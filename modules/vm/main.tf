resource "google_compute_instance" "default" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = "${var.region}-a" # Defaulting to zone 'a' for simplicity
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = var.network_id
    subnetwork = var.subnetwork_id

    # No access_config = no public IP (private only)
  }

  # Tag for IAP SSH access
  tags = ["iap-ssh"]

  # Standard user labels
  labels = var.labels

  # Service account with basic permissions
  # (default compute service account is usually enough for simple troubleshooting)
  service_account {
    scopes = ["cloud-platform"]
  }

  # Provide a simple startup script to install curl if not present
  metadata_startup_script = "apt-get update && apt-get install -y curl"

  lifecycle {
    ignore_changes = [
      attached_disk,
    ]
  }
}
