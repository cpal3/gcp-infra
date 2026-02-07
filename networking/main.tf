# =====================
# PROD Network Stack
# =====================
module "prod_host_project" {
  source = "../modules/project"

  name            = "prod-vpc-host"
  project_id_prefix = "prod-host"
  folder_id       = var.prod_folder_id
  billing_account = var.billing_account
  environment     = "prod"
  labels = {
    cost_center = "infrastructure"
    owner       = "platform-team"
    type        = "host-project"
  }
}

module "prod_vpc" {
  source = "../modules/network"

  project_id   = module.prod_host_project.project_id
  network_name = "prod-vpc"
  subnets = [
    {
      name   = "prod-subnet-a"
      cidr   = "10.0.1.0/24"
      region = var.region
      secondary_ranges = [
          { name = "pods", cidr = "10.1.0.0/16" }
      ]
    }
  ]
}

# =====================
# NON-PROD Network Stack
# =====================
module "non_prod_host_project" {
  source = "../modules/project"

  name            = "non-prod-vpc-host"
  project_id_prefix = "np-host"
  folder_id       = var.non_prod_folder_id
  billing_account = var.billing_account
  environment     = "non-prod"
  labels = {
    cost_center = "infrastructure"
    owner       = "platform-team"
    type        = "host-project"
  }
}

module "non_prod_vpc" {
  source = "../modules/network"

  project_id   = module.non_prod_host_project.project_id
  network_name = "non-prod-vpc"
  subnets = [
    {
      name   = "np-subnet-a"
      cidr   = "10.10.1.0/24"
      region = var.region
      secondary_ranges = [
          { name = "pods", cidr = "10.11.0.0/16" }
      ]
    }
  ]
}
