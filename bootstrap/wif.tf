# --- WORKLOAD IDENTITY FEDERATION ---

resource "google_iam_workload_identity_pool" "github_pool" {
  project                   = google_project.seed_project.project_id
  workload_identity_pool_id = "github-actions-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Identity pool for GitHub Actions"
  disabled                  = false
  depends_on                = [google_project_service.additional_apis]
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  project                            = google_project.seed_project.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Provider"
  description                        = "OIDC Identity Provider for GitHub Actions"
  disabled                           = false

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  
  attribute_condition = "assertion.repository == '${var.github_repo}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# --- BINDING: ALLOW GITHUB TO IMPERSONATE THE RUNNERS ---

resource "google_service_account_iam_binding" "wif_impersonation" {
  for_each           = google_service_account.runners
  service_account_id = each.value.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_repo}"
  ]
}
