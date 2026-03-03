# Provider version configuration is centralized in ../provider_versions.tf
# This ensures consistency across all infrastructure layers.

terraform {
  backend "gcs" {
    bucket = "ingr-seed-project-tfstate"
    prefix = "terraform/networking"
  }
}

provider "google" {
  region = var.region
}

locals {
  config = yamldecode(file("${path.module}/config.yaml"))
  
  # Extract project IDs from foundation outputs
  # We'll use data sources to reference existing projects
}

# Data sources to reference foundation projects
data "terraform_remote_state" "foundation" {
  backend = "gcs"
  config = {
    bucket = "ingr-seed-project-tfstate"
    prefix = "terraform/foundation"
  }
}

# Create VPCs using the network module
module "vpcs" {
  source   = "../modules/network"
  for_each = local.config.vpcs

  project_id              = data.terraform_remote_state.foundation.outputs.project_ids[each.value.project]
  network_name            = each.key
  routing_mode            = each.value.routing_mode
  enable_shared_vpc_host  = each.value.enable_shared_vpc_host
  enable_flow_logs        = each.value.enable_flow_logs
  subnets                 = each.value.subnets
}

# VPC Peering Connections
resource "google_compute_network_peering" "peerings" {
  for_each = { for p in local.config.peerings : "${p.name}-primary" => p }

  name                 = each.value.name
  network              = module.vpcs[each.value.network].network_self_link
  peer_network         = module.vpcs[each.value.peer_network].network_self_link
  export_custom_routes = lookup(each.value, "export_custom_routes", false)
  import_custom_routes = lookup(each.value, "import_custom_routes", false)
}

# Reverse peering (required for bidirectional peering)
resource "google_compute_network_peering" "peerings_reverse" {
  for_each = { for p in local.config.peerings : "${p.name}-reverse" => p }

  name                 = "${each.value.name}-reverse"
  network              = module.vpcs[each.value.peer_network].network_self_link
  peer_network         = module.vpcs[each.value.network].network_self_link
  export_custom_routes = lookup(each.value, "import_custom_routes", false)
  import_custom_routes = lookup(each.value, "export_custom_routes", false)
}
