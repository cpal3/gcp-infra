output "network_name" {
  value = google_compute_network.vpc.name
}

output "network_id" {
  value = google_compute_network.vpc.id
}

output "subnets" {
  value = { for k, v in google_compute_subnetwork.subnets : k => v.id }
}
