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
}

module "folders" {
  source = "../modules/folder"

  parent_id = "organizations/${var.org_id}"
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

  name              = "common-hub-net"
  project_id_prefix = var.project_id_prefix
  folder_id         = module.folders.ids["common"]
  billing_account   = var.billing_account
  environment       = "common"
  labels            = local.common_labels
  apis = [
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "dns.googleapis.com"
  ]
}

# --- CENTRAL LOGGING ---
module "common_logging" {
  source = "../modules/project"

  name              = "common-logging"
  project_id_prefix = var.project_id_prefix
  folder_id         = module.folders.ids["common"]
  billing_account   = var.billing_account
  environment       = "common"
  labels            = local.common_labels
  apis = [
    "logging.googleapis.com",
    "bigquery.googleapis.com",
    "storage.googleapis.com"
  ]
}

# --- PROD SHARED VPC HOST ---
module "prod_host" {
  source = "../modules/project"

  name              = "prod-host"
  project_id_prefix = var.project_id_prefix
  folder_id         = module.folders.ids["prod"]
  billing_account   = var.billing_account
  environment       = "prod"
  labels            = local.common_labels
  apis = [
    "compute.googleapis.com",
    "container.googleapis.com" # Often needed in prod-host for GKE
  ]
}

# --- NON-PROD SHARED VPC HOST ---
module "non_prod_host" {
  source = "../modules/project"

  name              = "non-prod-host"
  project_id_prefix = var.project_id_prefix
  folder_id         = module.folders.ids["non-prod"]
  billing_account   = var.billing_account
  environment       = "non-prod"
  labels            = local.common_labels
  apis = [
    "compute.googleapis.com",
    "container.googleapis.com"
  ]
}

# --- ORGANIZATION POLICIES ---

resource "google_organization_policy" "disable_sa_key_creation" {
  org_id     = var.org_id
  constraint = "constraints/iam.disableServiceAccountKeyCreation"

  boolean_policy {
    enforced = true
  }
}

resource "google_organization_policy" "disable_external_ip" {
  org_id     = var.org_id
  constraint = "constraints/compute.vmExternalIpAccess"

  list_policy {
    deny {
      all = true
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
