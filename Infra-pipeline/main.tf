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
  enable_fleet_registration = try(each.value.gke.enable_fleet_registration, false)
  labels                 = try(each.value.labels, {})
}

# =========================================================
# Artifact Registry Modules
# =========================================================
module "artifact_registry" {
  source   = "../modules/artifact_registry"
  for_each = { for k, v in local.projects : k => v if try(v.artifact_registry.enabled, false) }

  project_id = each.value.project_id
  region     = each.value.region
  repo_id    = each.value.artifact_registry.repo_id
  format     = try(each.value.artifact_registry.format, "DOCKER")
  labels     = try(each.value.labels, {})
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
  service_name    = each.value.cloud_run.service_name
  image           = try(each.value.cloud_run.image, "us-docker.pkg.dev/cloudrun/container/hello")
  service_account = try(each.value.cloud_run.service_account, null)
  network_id      = each.value.network_id
  subnetwork_id   = each.value.subnetwork_id
  labels          = try(each.value.labels, {})
}

# =========================================================
# Internal Load Balancer Modules
# =========================================================
module "load_balancer" {
  source   = "../modules/load_balancer"
  for_each = { for k, v in local.projects : k => v if try(v.load_balancer.enabled, false) }

  project_id    = each.value.project_id
  region        = each.value.region
  lb_name           = each.value.load_balancer.lb_name
  network_id        = each.value.network_id
  subnetwork_id     = each.value.subnetwork_id
  serverless_neg_id = try(module.cloud_run[each.key].serverless_neg_id, null)
  labels            = try(each.value.labels, {})
}

# =========================================================
# Testing VM Modules (for verification)
# =========================================================
module "vm" {
  source   = "../modules/vm"
  for_each = { for k, v in local.projects : k => v if try(v.testing_vm.enabled, false) }

  project_id    = each.value.project_id
  region        = each.value.region
  instance_name = each.value.testing_vm.instance_name
  machine_type  = try(each.value.testing_vm.machine_type, "e2-micro")
  network_id    = each.value.network_id
  subnetwork_id = each.value.subnetwork_id
  labels        = try(each.value.labels, {})
}

# =========================================================
# GKE Access to Artifact Registry
# =========================================================
resource "google_artifact_registry_repository_iam_member" "gke_pull_permission" {
  for_each   = module.artifact_registry
  project    = local.projects[each.key].project_id
  location   = local.projects[each.key].region
  repository = local.projects[each.key].artifact_registry.repo_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:890886578244-compute@developer.gserviceaccount.com"
}
