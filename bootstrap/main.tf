terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

provider "google" {
  region = var.region
}

# --- SEED PROJECT ---

resource "google_project" "seed_project" {
  name            = var.project_name
  project_id      = var.project_name
  billing_account = var.billing_account
  folder_id       = var.folder_id != "" ? var.folder_id : null
  org_id          = var.folder_id == "" ? var.org_id : null
  
  # Prevent accidental deletion of the seed project
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_project_service" "apis" {
  project = google_project.seed_project.project_id
  service = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "additional_apis" {
  project = google_project.seed_project.project_id
  for_each = toset([
    "iam.googleapis.com",
    "cloudbilling.googleapis.com",
    "serviceusage.googleapis.com",
    "storage-api.googleapis.com",
    "iamcredentials.googleapis.com" # Required for WIF
  ])
  service = each.key
  disable_on_destroy = false
  depends_on = [google_project_service.apis]
}

# --- TERRAFORM STATE BUCKET ---

resource "google_storage_bucket" "tf_state" {
  project                     = google_project.seed_project.project_id
  name                        = "${var.project_name}-tfstate"
  location                    = var.region
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
  force_destroy = false

  depends_on = [google_project_service.additional_apis]
}

# --- TERRAFORM RUNNERS (DYNAMIC CREATION) ---

resource "google_service_account" "runners" {
  for_each     = local.iam_config.service_accounts
  project      = google_project.seed_project.project_id
  account_id   = each.key
  display_name = lookup(each.value, "display_name", "${each.key} Service Account")
  depends_on   = [google_project_service.additional_apis]
}

# --- TERRAFORM RUNNERS IAM (DYNAMIC) ---

locals {
  iam_config = yamldecode(file("${path.module}/iam_roles.yaml"))

  # Map runner names to their service account emails dynamically
  runner_emails = {
    for name, sa in google_service_account.runners : name => sa.email
  }

  # Flatten org roles for all runners
  org_iam_bindings = flatten([
    for runner_name, config in local.iam_config.iam_roles : [
      for role in config.org : {
        role   = role
        member = "serviceAccount:${local.runner_emails[runner_name]}"
      }
    ]
  ])

  # Flatten project roles for all runners
  project_iam_bindings = flatten([
    for runner_name, config in local.iam_config.iam_roles : [
      for role in config.project : {
        role   = role
        member = "serviceAccount:${local.runner_emails[runner_name]}"
      }
    ]
  ])
}

module "runner_project_iam" {
  source    = "../modules/iam"
  mode      = "project"
  target_id = google_project.seed_project.project_id
  bindings  = local.project_iam_bindings
}

module "runner_org_iam" {
  source    = "../modules/iam"
  mode      = "organization"
  target_id = var.org_id
  bindings  = local.org_iam_bindings
}

# Output all runner emails
output "runner_emails" {
  value = {
    for name, sa in google_service_account.runners : name => sa.email
  }
}
