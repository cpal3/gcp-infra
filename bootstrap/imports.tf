# Temporary import blocks to bypass PowerShell quoting issues
# These will be removed after a successful apply

import {
  to = google_service_account.runners["foundation-runner"]
  id = "projects/ingr-seed-project/serviceAccounts/foundation-runner@ingr-seed-project.iam.gserviceaccount.com"
}
