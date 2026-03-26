output "forwarding_rule_ip" {
  description = "The IP address of the internal load balancer."
  value       = google_compute_forwarding_rule.default.ip_address
}

output "backend_service_id" {
  description = "The ID of the regional backend service."
  value       = google_compute_region_backend_service.default.id
}
