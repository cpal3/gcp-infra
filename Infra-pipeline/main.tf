terraform {
  backend "gcs" {
    bucket = "ingr-seed-project-tfstate"
    prefix = "terraform/infra-pipeline/projects"
  }
}

provider "google" {
  region = "asia-south1" # Note: Change to your default region
}

# ---------------------------------------------------------
# Data Sources from Foundation and Networking layers
# ---------------------------------------------------------

data "terraform_remote_state" "foundation" {
  backend = "gcs"
  config = {
    bucket = "ingr-seed-project-tfstate"
    prefix = "terraform/foundation"
  }
}

data "terraform_remote_state" "networking" {
  backend = "gcs"
  config = {
    bucket = "ingr-seed-project-tfstate"
    prefix = "terraform/networking"
  }
}

# ---------------------------------------------------------
# Example: Creating a new Service Project
# ---------------------------------------------------------

# module "app_project" {
#   source = "../modules/project"
#
#   name                = "my-app-db"
#   project_id_prefix   = "ingr"
#   folder_id           = data.terraform_remote_state.foundation.outputs.folder_ids["prod"]
#   billing_account     = "YOUR_BILLING_ACCOUNT_ID" 
#   environment         = "prod"
#   labels              = { cost_center = "web", owner = "team-a" }
#   apis                = ["compute.googleapis.com"]
# }

# ---------------------------------------------------------
# Example: Attaching the Service Project to the Shared VPC
# ---------------------------------------------------------

# module "app_project_attachment" {
#   source = "../modules/project_attachment"
#
#   # The Host Project created in the Networking/Foundation layer
#   host_project_id    = data.terraform_remote_state.foundation.outputs.project_ids["prod-host1"]
#   
#   # The newly created Service Project above
#   service_project_id = module.app_project.project_id
#
#   # (Optional) Granting users NetworkUser on a specific subnet
#   subnetwork         = "prod-subnet-asia-south1"
#   region             = "asia-south1"
#   subnet_users       = [
#     "serviceAccount:my-sa@my-app-db.iam.gserviceaccount.com"
#   ]
# }
