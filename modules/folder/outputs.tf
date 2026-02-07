output "ids" {
  description = "Map of folder names to folder IDs."
  value       = merge(
    { (var.names[0]) = google_folder.folder.name },
    { for k, v in google_folder.subfolders : var.names[k + 1] => v.name }
  )
}
