resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  project       = var.project_id
  repository_id = var.repo_id
  description   = "Artifact Registry Repository for ${var.repo_id}"
  format        = var.format
  labels        = var.labels

  # Cleanup policy (optional but recommended for CI/CD)
  cleanup_policies {
    id     = "delete-old-images"
    action = "DELETE"
    condition {
      tag_state    = "ANY"
      older_than   = "30d" # Delete images older than 30 days
    }
  }

  cleanup_policies {
    id     = "keep-last-5"
    action = "KEEP"
    most_recent_versions {
      keep_count = 5
    }
  }
}

output "repo_name" {
  value = google_artifact_registry_repository.repo.name
}

output "repo_location" {
  value = google_artifact_registry_repository.repo.location
}
