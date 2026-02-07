variable "target_id" {
  description = "The ID of the project or folder to apply IAM to."
  type        = string
}

variable "mode" {
  description = "One of 'project', 'folder', or 'organization'."
  type        = string
  default     = "project"
  validation {
    condition     = contains(["project", "folder", "organization"], var.mode)
    error_message = "Mode must be 'project', 'folder', or 'organization'."
  }
}

variable "bindings" {
  description = "List of maps containing role and member."
  type = list(object({
    role   = string
    member = string
  }))
}
