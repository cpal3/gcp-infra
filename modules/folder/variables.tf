variable "names" {
  description = "List of folder names. First name is the parent, subsequent names are children of that parent (flat hierarchy under the first)."
  type        = list(string)
}

variable "parent_id" {
  description = "The resource name of the parent Folder or Organization. Format: folders/{folder_id} or organizations/{org_id}"
  type        = string
}
