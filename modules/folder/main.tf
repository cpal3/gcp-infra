resource "google_folder" "folder" {
  display_name = var.names[0]
  parent       = var.parent_id
}

resource "google_folder" "subfolders" {
  count        = length(var.names) > 1 ? length(var.names) - 1 : 0
  display_name = var.names[count.index + 1]
  parent       = google_folder.folder.name
}
