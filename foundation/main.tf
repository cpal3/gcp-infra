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

  name              = each.key
  project_id_prefix = var.project_id_prefix
  project_id        = lookup(each.value, "project_id", null)
  folder_id         = module.folders.ids[each.value.folder]
  billing_account   = var.billing_account
  environment       = each.value.environment
  labels            = local.common_labels
  apis              = each.value.apis
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

# --- CENTRALIZED LOGGING (ORG LEVEL) ---

# 1. Create a Log Bucket in the Logging Project
resource "google_logging_project_bucket_config" "org_log_bucket" {
  project        = module.projects["logging"].project_id
  location       = "global"
  retention_days = 30
  bucket_id      = "org-central-logs"
}

# 2. Create the Org-level Log Sink
resource "google_logging_organization_sink" "org_sink" {
  name             = "org-central-sink"
  description      = "Centralized sink for all organization logs"
  org_id           = var.org_id
  destination      = "logging.googleapis.com/${google_logging_project_bucket_config.org_log_bucket.id}"
  include_children = true
}

# 3. Grant the Sink's Service Account permission to write to the Logging Project
resource "google_project_iam_member" "log_sink_member" {
  project = module.projects["logging"].project_id
  role    = "roles/logging.bucketWriter"
  member  = google_logging_organization_sink.org_sink.writer_identity
}

# --- VPC NETWORKS ---

module "vpcs" {
  source   = "../modules/network"
  for_each = lookup(local.config, "vpcs", {})

  project_id              = module.projects[each.value.project].project_id
  network_name            = each.key
  routing_mode            = each.value.routing_mode
  enable_shared_vpc_host  = each.value.enable_shared_vpc_host
  enable_flow_logs        = each.value.enable_flow_logs
  subnets                 = each.value.subnets

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
