resource "google_sql_database_instance" "default" {
  name             = var.instance_name
  database_version = var.database_version
  region           = var.region
  project          = var.project_id

  settings {
    tier = var.tier
    
    user_labels = var.labels

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network_id

      # The allocated ip range for private services access (must be created centrally)
      allocated_ip_range = var.allocated_ip_range
    }
  }

  # Set to true because it's a best practice, but typically managed separately or securely
  deletion_protection = false 
}

resource "google_sql_database" "database" {
  name     = "${var.instance_name}-db"
  instance = google_sql_database_instance.default.name
  project  = var.project_id
}

resource "google_sql_user" "users" {
  name     = "appuser"
  instance = google_sql_database_instance.default.name
  project  = var.project_id
  password = "changeme" # In a real environment, use Secret Manager or Random Provider
}
