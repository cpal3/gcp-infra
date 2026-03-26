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
  }

  labels = var.labels
}

# Ensure the service can be invoked securely if needed (e.g. by an internal LB or other internal service)
# Here we'll just output the default IAM so it requires authentication
