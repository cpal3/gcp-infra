module "folders" {
  source = "../modules/folder"

  parent_id = "organizations/${var.org_id}"
  names = [
    "prod",
    "non-prod",
    "common",
    "bootstrap"
  ]
}

# Example of applying IAM to the Infrastructure folder
module "infra_iam" {
  source = "../modules/iam"

  mode      = "folder"
  target_id = module.folders.ids["common"]
  bindings = [
    {
      role   = "roles/resourcemanager.folderViewer"
      member = "group:gcp-viewers@example.com"
    }
  ]
}
