output "seed_project_id" {
  description = "The ID of the created seed project."
  value       = google_project.seed_project.project_id
}

output "terraform_state_bucket" {
  description = "The name of the GCS bucket for Terraform state."
  value       = google_storage_bucket.tf_state.name
}

output "terraform_runner_service_account_email" {
  description = "The email of the Service Account to be used by CI/CD."
  value       = google_service_account.terraform_runner.email
}

output "workload_identity_provider" {
  description = "The full resource name of the Workload Identity Provider, used in GitHub Actions YAML."
  value       = google_iam_workload_identity_pool_provider.github_provider.name
}
