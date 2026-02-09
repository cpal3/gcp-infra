resource "random_id" "suffix" {
  byte_length = 4
}

resource "google_project" "project" {
  name            = var.name
  project_id      = "${var.project_id_prefix}-${var.name}-${random_id.suffix.hex}"
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
