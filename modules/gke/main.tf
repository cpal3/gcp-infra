resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.regional ? var.region : var.zones[0]
  project  = var.project_id

  deletion_protection = var.deletion_protection

  network    = var.network_id
  subnetwork = var.subnetwork_id

  # Security: Datapath V2 (Better performance and security)
  datapath_provider = "ADVANCED_DATAPATH"

  # Security: Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  # Private Cluster Config
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }


  # Scalability: Vertical Pod Autoscaling
  vertical_pod_autoscaling {
    enabled = true
  }

  # Scalability: Release Channel
  release_channel {
    channel = var.release_channel
  }

  # Security: Network Policy (Not required for Datapath V2 as it's built-in)
  network_policy {
    enabled  = false
  }

  addons_config {
    network_policy_config {
      disabled = true
    }
  }

  # Scalability: Node Auto-Provisioning (NAP)
  cluster_autoscaling {
    enabled = var.enable_nap
    dynamic "resource_limits" {
      for_each = var.enable_nap ? [1] : []
      content {
        resource_type = "cpu"
        minimum       = 1
        maximum       = 100
      }
    }
    dynamic "resource_limits" {
      for_each = var.enable_nap ? [1] : []
      content {
        resource_type = "memory"
        minimum       = 1
        maximum       = 1000
      }
    }
    auto_provisioning_defaults {
      service_account = "default" # Or a specific SA if created
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform"
      ]
    }
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.ip_range_pods
    services_secondary_range_name = var.ip_range_services
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  resource_labels = var.labels
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.regional ? var.region : var.zones[0]
  project    = var.project_id
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  # Scalability: Autoscaling
  dynamic "autoscaling" {
    for_each = var.enable_autoscaling ? [1] : []
    content {
      min_node_count = var.min_node_count
      max_node_count = var.max_node_count
    }
  }

  # For regional clusters, specify multi-zone distribution if zones are provided
  node_locations = var.regional && length(var.zones) > 0 ? var.zones : null

  node_config {
    machine_type = var.machine_type
    labels       = var.labels

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
