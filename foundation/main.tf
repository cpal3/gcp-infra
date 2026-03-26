# Provider version configuration is centralized in ../provider_versions.tf
# This ensures consistency across all infrastructure layers.

terraform {
  backend "gcs" {
    bucket = "ingr-seed-project-tfstate"
    prefix = "terraform/foundation"
  }
}

provider "google" {
  region = var.region
}

locals {
  common_labels = {
    cost_center = var.cost_center
    owner       = var.owner
  }
  config = yamldecode(file("${path.module}/config.yaml"))

  iam_config = yamldecode(file("${path.module}/iam_roles.yaml"))
}

# IPAM Module for automatic IP allocation
module "ipam" {
  source = "../modules/ipam"
}

# --- INFRASTRUCTURE RESOURCES ---

module "folders" {
  source = "../modules/folder"

  parent_id           = "organizations/${var.org_id}"
  deletion_protection = var.deletion_protection
  names               = local.config.folders
}

# --- DYNAMIC PROJECTS ---
module "projects" {
  source   = "../modules/project"
  for_each = local.config.projects

  name                = each.key
  project_id_prefix   = var.project_id_prefix
  project_id          = lookup(each.value, "project_id", null)
  folder_id           = module.folders.ids[each.value.folder]
  billing_account     = var.billing_account
  environment         = each.value.environment
  labels              = {
    cost_center   = each.value.cost_center
    business_unit = each.value.business_unit
    owner         = var.owner
  }
  apis                = each.value.apis
  deletion_protection = var.deletion_protection
}

# --- DELETION PROTECTION (LIENS) ---
resource "google_resource_manager_lien" "project_liens" {
  for_each = var.deletion_protection ? module.projects : {}

  parent       = "projects/${each.value.project_id}"
  restrictions = ["resourcemanager.projects.delete"]
  origin       = "terraform-foundation-protection"
  reason       = "Enterprise Landing Zone Foundation Project. Essential resource."
}

# --- ORGANIZATION POLICIES ---
resource "google_organization_policy" "org_policies" {
  for_each = { for p in local.config.org_policies : p.constraint => p }

  org_id     = var.org_id
  constraint = each.value.constraint

  dynamic "boolean_policy" {
    for_each = lookup(each.value, "is_list", false) == false ? [1] : []
    content {
      enforced = each.value.enforce
    }
  }

  dynamic "list_policy" {
    for_each = lookup(each.value, "is_list", false) == true ? [1] : []
    content {
      deny {
        all = each.value.enforce
      }
    }
  }
}

# --- CENTRALIZED LOGGING ---

locals {
  log_cfg = lookup(local.config, "logging", {})
}

# 1. Log Bucket in the Logging Project (hot storage, queryable in Log Explorer)
resource "google_logging_project_bucket_config" "org_log_bucket" {
  project        = module.projects[local.log_cfg.project].project_id
  location       = "global"
  retention_days = local.log_cfg.retention_days
  bucket_id      = local.log_cfg.log_bucket_id
}

# 2. Org-level Sink → Log Bucket
resource "google_logging_organization_sink" "org_sink" {
  name             = local.log_cfg.sink_name
  description      = "Centralized org sink — all logs to log bucket"
  org_id           = var.org_id
  destination      = "logging.googleapis.com/${google_logging_project_bucket_config.org_log_bucket.id}"
  filter           = local.log_cfg.filter
  include_children = true
}

# 3. Grant Sink SA permission to write to Log Bucket
resource "google_project_iam_member" "log_sink_member" {
  project = module.projects[local.log_cfg.project].project_id
  role    = "roles/logging.bucketWriter"
  member  = google_logging_organization_sink.org_sink.writer_identity
}

# 4. GCS Archive Bucket (long-term retention / compliance)
resource "google_storage_bucket" "log_archive" {
  count         = lookup(try(local.log_cfg.gcs, {}), "enabled", true) ? 1 : 0
  name          = "${module.projects[local.log_cfg.project].project_id}-log-archive"
  project       = module.projects[local.log_cfg.project].project_id
  location      = local.log_cfg.gcs.location
  force_destroy = false
  labels        = local.common_labels
  uniform_bucket_level_access = true

  retention_policy {
    retention_period = local.log_cfg.gcs.retention_days * 86400 # days → seconds
  }

  lifecycle_rule {
    condition { age = 90 }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition { age = 365 }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }
}

# 5. Org-level Sink → GCS Archive
resource "google_logging_organization_sink" "org_sink_gcs" {
  count            = lookup(try(local.log_cfg.gcs, {}), "enabled", true) ? 1 : 0
  name             = "${local.log_cfg.sink_name}-gcs"
  description      = "Centralized org sink — all logs to GCS archive"
  org_id           = var.org_id
  destination      = "storage.googleapis.com/${google_storage_bucket.log_archive[0].name}"
  filter           = local.log_cfg.filter
  include_children = true
}

# 6. Grant GCS Sink SA permission to write to archive bucket
resource "google_storage_bucket_iam_member" "log_archive_sink_member" {
  count  = lookup(try(local.log_cfg.gcs, {}), "enabled", true) ? 1 : 0
  bucket = google_storage_bucket.log_archive[0].name
  role   = "roles/storage.objectCreator"
  member = google_logging_organization_sink.org_sink_gcs[0].writer_identity
}

# BigQuery sink — reserved for future log analytics
# resource "google_bigquery_dataset" "org_logs" { ... }
# resource "google_logging_organization_sink" "org_sink_bq" { ... }


# --- VPC NETWORKS ---

module "vpcs" {
  source   = "../modules/network"
  for_each = lookup(local.config, "vpcs", {})

  project_id             = module.projects[each.value.project].project_id
  network_name           = each.key
  routing_mode           = each.value.routing_mode
  enable_shared_vpc_host = each.value.enable_shared_vpc_host
  enable_flow_logs       = each.value.enable_flow_logs
  subnets                = each.value.subnets

  depends_on = [module.projects]
}

# --- VPC PEERING ---

resource "google_compute_network_peering" "peerings" {
  for_each = { for p in lookup(local.config, "peerings", []) : "${p.name}-primary" => p }

  name                 = each.value.name
  network              = module.vpcs[each.value.network].network_self_link
  peer_network         = module.vpcs[each.value.peer_network].network_self_link
  export_custom_routes = lookup(each.value, "export_custom_routes", false)
  import_custom_routes = lookup(each.value, "import_custom_routes", false)

  depends_on = [module.vpcs]
}

# Reverse peering (required for bidirectional peering)
resource "google_compute_network_peering" "peerings_reverse" {
  for_each = { for p in lookup(local.config, "peerings", []) : "${p.name}-reverse" => p }

  name                 = "${each.value.name}-reverse"
  network              = module.vpcs[each.value.peer_network].network_self_link
  peer_network         = module.vpcs[each.value.network].network_self_link
  export_custom_routes = lookup(each.value, "import_custom_routes", false)
  import_custom_routes = lookup(each.value, "export_custom_routes", false)

  depends_on = [module.vpcs]
}

# --- FIREWALL RULES ---

locals {
  # Flatten vpc -> firewall_rules into a map keyed by "vpc_name-rule_name"
  firewall_rules = merge([
    for vpc_name, vpc in lookup(local.config, "vpcs", {}) : {
      for rule in lookup(vpc, "firewall_rules", []) :
      "${vpc_name}-${rule.name}" => merge(rule, {
        vpc_name   = vpc_name
        project_id = module.projects[vpc.project].project_id
      })
    }
  ]...)
}

resource "google_compute_firewall" "rules" {
  for_each = local.firewall_rules

  name          = each.value.name
  network       = module.vpcs[each.value.vpc_name].network_self_link
  project       = each.value.project_id
  direction     = each.value.direction
  priority      = each.value.priority
  source_ranges = lookup(each.value, "source_ranges", [])
  target_tags   = lookup(each.value, "target_tags", null)

  dynamic "allow" {
    for_each = lookup(each.value, "allow", [])
    content {
      protocol = allow.value.protocol
      ports    = lookup(allow.value, "ports", [])
    }
  }

  dynamic "deny" {
    for_each = lookup(each.value, "deny", [])
    content {
      protocol = deny.value.protocol
    }
  }

  depends_on = [module.vpcs]
}

# --- SERVICE ACCOUNTS ---

resource "google_service_account" "service_accounts" {
  for_each = { for sa in lookup(local.config, "service_accounts", []) : "${sa.project}-${sa.account_id}" => sa }

  account_id   = each.value.account_id
  display_name = lookup(each.value, "display_name", "Service Account ${each.value.account_id}")
  project      = module.projects[each.value.project].project_id
}

# --- PROJECT IAM BINDINGS ---

locals {
  # Flatten the project_iam_bindings list from iam_roles.yaml to iterate easily
  flattened_project_iam = flatten([
    for binding in lookup(local.iam_config, "project_iam_bindings", []) : [
      for role in try(binding.roles, length(try(binding.role, "")) > 0 ? [binding.role] : []) : [
        for member in binding.members : {
          project = binding.project
          role    = role
          member  = member
        }
      ]
    ]
  ])

  # Flatten the subnetwork_iam_bindings list from iam_roles.yaml
  flattened_subnetwork_iam = flatten([
    for binding in lookup(local.iam_config, "subnetwork_iam_bindings", []) : [
      for role in try(binding.roles, length(try(binding.role, "")) > 0 ? [binding.role] : []) : [
        for member in binding.members : {
          project    = binding.project
          region     = binding.region
          subnetwork = binding.subnetwork
          role       = role
          member     = member
        }
      ]
    ]
  ])
}

resource "google_compute_subnetwork_iam_member" "subnetwork_iam_bindings" {
  for_each = { for b in local.flattened_subnetwork_iam : "${b.project}-${b.region}-${b.subnetwork}-${b.role}-${b.member}" => b }

  project    = try(module.projects[each.value.project].project_id, each.value.project)
  region     = each.value.region
  subnetwork = each.value.subnetwork
  role       = each.value.role
  member     = each.value.member

  depends_on = [module.project_attachments, google_service_account.service_accounts]
}

resource "google_project_iam_member" "project_iam_bindings" {
  for_each = { for b in local.flattened_project_iam : "${b.project}-${b.role}-${b.member}" => b }

  project = module.projects[each.value.project].project_id
  role    = each.value.role
  member  = each.value.member

  depends_on = [google_service_account.service_accounts]
}

# --- SHARED VPC PROJECT ATTACHMENTS ---

module "project_attachments" {
  source   = "../modules/project_attachment"
  for_each = { for idx, att in lookup(local.config, "project_attachments", []) : "${att.host_project}-${att.service_project}" => att }

  # Look up dynamically created projects if they reside in the same config
  host_project_id    = try(module.projects[each.value.host_project].project_id, each.value.host_project)
  service_project_id = try(module.projects[each.value.service_project].project_id, each.value.service_project)

  subnetwork   = lookup(each.value, "subnetwork", "")
  region       = lookup(each.value, "region", "")
  subnet_users = lookup(each.value, "users", [])

  depends_on = [module.vpcs, module.projects]
}
