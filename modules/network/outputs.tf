output "network_name" {
  value = google_compute_network.vpc.name
}

output "network_id" {
  value = google_compute_network.vpc.id
}

output "network_self_link" {
  value = google_compute_network.vpc.self_link
}

output "subnets" {
  value = { for k, v in google_compute_subnetwork.subnets : k => v.id }
}

output "is_shared_vpc_host" {
  value = var.enable_shared_vpc_host
}
