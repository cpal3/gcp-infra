terraform {
  backend "gcs" {
    bucket = "ingr-seed-project-tfstate"
    prefix = "terraform/infra-pipeline/projects"
  }
}

provider "google" {
  region = "asia-south1"
}

locals {
  # Parse config.yaml safely
  raw_config = yamldecode(file("${path.module}/config.yaml"))
  
  # Ensure projects map exists
  projects = try(local.raw_config.projects, {})
}

# =========================================================
# GKE Modules
# =========================================================
module "gke" {
  source   = "../modules/gke"
  for_each = { for k, v in local.projects : k => v if try(v.gke.enabled, false) }

  project_id             = each.value.project_id
  region                 = each.value.region
  cluster_name           = each.value.gke.cluster_name
  deletion_protection    = try(each.value.gke.deletion_protection, false)
  regional               = try(each.value.gke.regional, true)
  zones                  = try(each.value.gke.zones, [])
  network_id             = each.value.network_id
  subnetwork_id          = each.value.subnetwork_id
  master_authorized_networks = try(each.value.gke.master_authorized_networks, [])
  node_count             = try(each.value.gke.node_count, 1)
  machine_type           = try(each.value.gke.machine_type, "e2-medium")
  master_ipv4_cidr_block = each.value.gke.master_ipv4_cidr_block
  enable_private_endpoint = try(each.value.gke.enable_private_endpoint, true)
  enable_autoscaling     = try(each.value.gke.enable_autoscaling, true)
  min_node_count         = try(each.value.gke.min_node_count, 1)
  max_node_count         = try(each.value.gke.max_node_count, 5)
  enable_nap             = try(each.value.gke.enable_nap, true)
  enable_network_policy  = try(each.value.gke.enable_network_policy, true)
  release_channel        = try(each.value.gke.release_channel, "REGULAR")
  ip_range_pods          = each.value.gke.ip_range_pods
  ip_range_services      = each.value.gke.ip_range_services
  labels                 = try(each.value.labels, {})
}

# =========================================================
# Cloud SQL Modules
# =========================================================
module "cloud_sql" {
  source   = "../modules/cloud_sql"
  for_each = { for k, v in local.projects : k => v if try(v.cloud_sql.enabled, false) }

  project_id         = each.value.project_id
  region             = each.value.region
  instance_name      = each.value.cloud_sql.instance_name
  database_version   = try(each.value.cloud_sql.database_version, "POSTGRES_15")
  tier               = try(each.value.cloud_sql.tier, "db-f1-micro")
  network_id         = each.value.network_id
  allocated_ip_range = try(each.value.cloud_sql.allocated_ip_range, null)
  labels             = try(each.value.labels, {})
}

# =========================================================
# Cloud Run Modules
# =========================================================
module "cloud_run" {
  source   = "../modules/cloud_run"
  for_each = { for k, v in local.projects : k => v if try(v.cloud_run.enabled, false) }

  project_id    = each.value.project_id
  region        = each.value.region
  service_name  = each.value.cloud_run.service_name
  image         = try(each.value.cloud_run.image, "us-docker.pkg.dev/cloudrun/container/hello")
  network_id    = each.value.network_id
  subnetwork_id = each.value.subnetwork_id
  labels        = try(each.value.labels, {})
}

# =========================================================
# Internal Load Balancer Modules
# =========================================================
module "load_balancer" {
  source   = "../modules/load_balancer"
  for_each = { for k, v in local.projects : k => v if try(v.load_balancer.enabled, false) }

  project_id    = each.value.project_id
  region        = each.value.region
  lb_name       = each.value.load_balancer.lb_name
  network_id    = each.value.network_id
  subnetwork_id = each.value.subnetwork_id
  labels        = try(each.value.labels, {})
}
