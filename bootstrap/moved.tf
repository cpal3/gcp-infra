# Migration from explicit resources to dynamic maps
# This prevents deletion/recreation of critical identities

moved {
  from = google_service_account.terraform_runner
  to   = google_service_account.runners["terraform-runner"]
}

moved {
  from = google_service_account.foundation_runner
  to   = google_service_account.runners["foundation-runner"]
}

moved {
  from = google_service_account_iam_binding.wif_impersonation
  to   = google_service_account_iam_binding.wif_impersonation["terraform-runner"]
}

moved {
  from = google_service_account_iam_binding.foundation_wif_impersonation
  to   = google_service_account_iam_binding.wif_impersonation["foundation-runner"]
}
