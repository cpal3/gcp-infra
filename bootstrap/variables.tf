variable "org_id" {
  description = "The Organization ID where the seed project will be created."
  type        = string
}

variable "billing_account" {
  description = "The Billing Account ID to attach to the seed project."
  type        = string
}

variable "folder_id" {
  description = "The Folder ID where the seed project will be created (optional). If not provided, project is created at Org root."
  type        = string
  default     = ""
}

variable "project_name" {
  description = "The name of the seed project."
  type        = string
  default     = "seed-project"
}

variable "region" {
  description = "The default region for resources (e.g., storage buckets)."
  type        = string
  default     = "us-central1"
}

variable "github_repo" {
  description = "The GitHub repository to allow OIDC access (format: user/repo)."
  type        = string
}
