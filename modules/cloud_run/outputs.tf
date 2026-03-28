output "service_name" {
  description = "The name of the Cloud Run service."
  value       = google_cloud_run_v2_service.default.name
}

output "service_uri" {
  description = "The URI of the Cloud Run service."
  value       = google_cloud_run_v2_service.default.uri
}

output "serverless_neg_id" {
  description = "The ID of the Serverless NEG for this service."
  value       = google_compute_region_network_endpoint_group.serverless_neg.id
}
