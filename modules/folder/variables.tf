variable "names" {
  description = "List of folder names to create as siblings under the parent_id."
  type        = list(string)
}

variable "parent_id" {
  description = "The resource name of the parent Folder or Organization. Format: folders/{folder_id} or organizations/{org_id}"
  type        = string
}
