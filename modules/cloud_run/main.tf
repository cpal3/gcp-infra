resource "google_cloud_run_v2_service" "default" {
  name     = var.service_name
  location = var.region
  project  = var.project_id

  ingress = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  template {
    containers {
      image = var.image
      
      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
      }
    }

    vpc_access {
      network_interfaces {
        network    = var.network_id
        subnetwork = var.subnetwork_id
      }
      egress = "ALL_TRAFFIC"
    }
    
    service_account = var.service_account
  }

  labels = var.labels
}

# --- SERVERLESS NEG ---
# Create a Serverless Network Endpoint Group (NEG) for the Internal Load Balancer
resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  name                  = "${var.service_name}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  project               = var.project_id

  cloud_run {
    service = google_cloud_run_v2_service.default.name
  }
}

# Ensure the service can be invoked securely if needed (e.g. by an internal LB or other internal service)
# Here we'll just output the default IAM so it requires authentication
