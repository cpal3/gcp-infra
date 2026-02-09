terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
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

  # Helper to identify projects for liens
  project_ids = {
    common-hub-net = module.common_hub_net.project_id
    common-logging = module.common_logging.project_id
    prod-host      = module.prod_host.project_id
    non-prod-host  = module.non_prod_host.project_id
  }

  iam_config = yamldecode(file("${path.module}/iam_roles.yaml"))
}

# --- INFRASTRUCTURE RESOURCES ---

module "folders" {
  source = "../modules/folder"

  parent_id           = "organizations/${var.org_id}"
  deletion_protection = var.deletion_protection
  names = [
    "prod",
    "non-prod",
    "common",
    "bootstrap"
  ]
}

# --- CENTRAL NETWORKING HUB ---
module "common_hub_net" {
  source = "../modules/project"

  name              = "hub-net"
  project_id_prefix = var.project_id_prefix
  project_id        = "ingr-hub-net-763224ae"
  folder_id         = module.folders.ids["common"]
  billing_account   = var.billing_account
  environment       = "common"
  labels            = local.common_labels
  apis              = local.config.project_apis.hub_net
  deletion_protection = var.deletion_protection
}

# --- CENTRAL LOGGING ---
module "common_logging" {
  source = "../modules/project"

  name              = "logging"
  project_id_prefix = var.project_id_prefix
  project_id        = "ingr-logging-763224ae"
  folder_id         = module.folders.ids["common"]
  billing_account   = var.billing_account
  environment       = "common"
  labels            = local.common_labels
  apis              = local.config.project_apis.logging
  deletion_protection = var.deletion_protection
}

# --- PROD SHARED VPC HOST ---
module "prod_host" {
  source = "../modules/project"

  name              = "prod-host"
  project_id_prefix = var.project_id_prefix
  project_id        = "ingr-prod-host-763224ae"
  folder_id         = module.folders.ids["prod"]
  billing_account   = var.billing_account
  environment       = "prod"
  labels            = local.common_labels
  apis              = local.config.project_apis.prod_host
  deletion_protection = var.deletion_protection
}

# --- NON-PROD SHARED VPC HOST ---
module "non_prod_host" {
  source = "../modules/project"

  name              = "nonprod-host"
  project_id_prefix = var.project_id_prefix
  project_id        = "ingr-nonprod-host-763224ae"
  folder_id         = module.folders.ids["non-prod"]
  billing_account   = var.billing_account
  environment       = "non-prod"
  labels            = local.common_labels
  apis              = local.config.project_apis.nonprod_host
  deletion_protection = var.deletion_protection
}

# --- DELETION PROTECTION (LIENS) ---
resource "google_resource_manager_lien" "project_liens" {
  for_each = var.deletion_protection ? local.project_ids : {}

  parent       = "projects/${each.value}"
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
  project        = module.common_logging.project_id
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
  project = module.common_logging.project_id
  role    = "roles/logging.bucketWriter"
  member  = google_logging_organization_sink.org_sink.writer_identity
}
