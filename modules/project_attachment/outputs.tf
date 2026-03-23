output "service_project_id" {
  description = "The ID of the attached service project."
  value       = google_compute_shared_vpc_service_project.service_project.id
}
