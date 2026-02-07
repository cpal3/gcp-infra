resource "google_project_iam_member" "project_iam" {
  for_each = var.mode == "project" ? { for m in var.bindings : "${m.role}.${m.member}" => m } : {}

  project = var.target_id
  role    = each.value.role
  member  = each.value.member
}

resource "google_folder_iam_member" "folder_iam" {
  for_each = var.mode == "folder" ? { for m in var.bindings : "${m.role}.${m.member}" => m } : {}

  folder = var.target_id
  role   = each.value.role
  member = each.value.member
}

resource "google_organization_iam_member" "org_iam" {
  for_each = var.mode == "organization" ? { for m in var.bindings : "${m.role}.${m.member}" => m } : {}

  org_id = var.target_id
  role   = each.value.role
  member = each.value.member
}
