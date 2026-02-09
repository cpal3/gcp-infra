output "ids" {
  description = "Map of folder names to folder IDs."
  value       = { for k, v in google_folder.folders : k => v.name }
}
