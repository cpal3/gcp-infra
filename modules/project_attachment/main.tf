resource "google_compute_shared_vpc_service_project" "service_project" {
  host_project    = var.host_project_id
  service_project = var.service_project_id
}

resource "google_compute_subnetwork_iam_member" "subnet_users" {
  for_each   = var.subnetwork != "" ? toset(var.subnet_users) : toset([])
  
  project    = var.host_project_id
  region     = var.region
  subnetwork = var.subnetwork
  role       = "roles/compute.networkUser"
  member     = each.key

  depends_on = [google_compute_shared_vpc_service_project.service_project]
}
