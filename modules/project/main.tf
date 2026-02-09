# Resource random_id removed to ensure Project IDs are stable and do not change on every run.
# Uniqueness is managed by the var.name and var.project_id_prefix.

resource "google_project" "project" {
  name            = var.name
  project_id      = var.project_id != null ? var.project_id : "${var.project_id_prefix}-${var.name}"
  folder_id       = var.folder_id
  billing_account = var.billing_account
  labels          = merge(var.labels, { environment = var.environment })

  # Allow destruction if the variable is false
  deletion_policy = var.deletion_protection ? "PREVENT" : "DELETE"
}

resource "google_project_service" "apis" {
  for_each = toset(var.apis)
  project  = google_project.project.project_id
  service  = each.key

  disable_on_destroy = false
}
