variable "target_id" {
  description = "The ID of the project or folder to apply IAM to."
  type        = string
}

variable "mode" {
  description = "One of 'project' or 'folder'."
  type        = string
  default     = "project"
  validation {
    condition     = contains(["project", "folder"], var.mode)
    error_message = "Mode must be 'project' or 'folder'."
  }
}

variable "bindings" {
  description = "List of maps containing role and member."
  type = list(object({
    role   = string
    member = string
  }))
}
