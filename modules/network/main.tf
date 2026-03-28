resource "google_compute_network" "vpc" {
  name                    = var.network_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
}

resource "google_compute_subnetwork" "subnets" {
  for_each = { for s in var.subnets : s.name => s }

  name                     = each.value.name
  ip_cidr_range            = each.value.cidr
  region                   = each.value.region
  network                  = google_compute_network.vpc.id
  project                  = var.project_id
  private_ip_google_access = each.value.purpose == "REGIONAL_MANAGED_PROXY" ? null : lookup(each.value, "private_google_access", true)
  purpose                  = each.value.purpose
  role                     = each.value.role

  dynamic "secondary_ip_range" {
    for_each = lookup(each.value, "secondary_ranges", [])
    content {
      range_name    = secondary_ip_range.value.name
      ip_cidr_range = secondary_ip_range.value.cidr
    }
  }

  dynamic "log_config" {
    for_each = var.enable_flow_logs && each.value.purpose != "REGIONAL_MANAGED_PROXY" ? [1] : []
    content {
      aggregation_interval = "INTERVAL_5_SEC"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }
}

# Firewall rules are managed by the foundation layer via config.yaml
# (google_compute_firewall.rules in foundation/main.tf)

# Enable Shared VPC if requested
resource "google_compute_shared_vpc_host_project" "host" {
  count   = var.enable_shared_vpc_host ? 1 : 0
  project = var.project_id

  depends_on = [google_compute_network.vpc]
}

# --- PRIVATE SERVICES ACCESS (PSA) ---
# Required for Cloud SQL, MemoryStore, etc. to use Private IP
# Establishing a peering with the Google-managed "servicenetworking" VPC

resource "google_compute_global_address" "private_ip_alloc" {
  for_each = { for cfg in var.private_service_access_configs : cfg.name => cfg }

  name          = each.value.name
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = each.value.prefix_length
  address       = each.value.address
  network       = google_compute_network.vpc.id
  project       = var.project_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count = length(var.private_service_access_configs) > 0 ? 1 : 0

  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [for cfg in var.private_service_access_configs : google_compute_global_address.private_ip_alloc[cfg.name].name]

  depends_on = [google_compute_global_address.private_ip_alloc]
}
