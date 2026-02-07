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

# --- TERRAFORM RUNNER SERVICE ACCOUNT ---

resource "google_service_account" "terraform_runner" {
  project      = google_project.seed_project.project_id
  account_id   = "terraform-runner"
  display_name = "Terraform Runner Service Account"
  depends_on   = [google_project_service.additional_apis]
}

# --- TERRAFORM RUNNER IAM (YAML DRIVEN) ---

locals {
  iam_config = yamldecode(file("${path.module}/iam_roles.yaml"))
}

module "runner_project_iam" {
  source    = "../modules/iam"
  mode      = "project"
  target_id = google_project.seed_project.project_id
  bindings = [
    for role in local.iam_config.project_roles : {
      role   = role
      member = "serviceAccount:${google_service_account.terraform_runner.email}"
    }
  ]
}

module "runner_org_iam" {
  source    = "../modules/iam"
  mode      = "organization"
  target_id = var.org_id
  bindings = [
    for role in local.iam_config.org_roles : {
      role   = role
      member = "serviceAccount:${google_service_account.terraform_runner.email}"
    }
  ]
}

# Ideally, this SA needs Org Admin or Folder Admin to create subsequent projects.
# We output its email so you can grant it those permissions manually or via a separate step.
