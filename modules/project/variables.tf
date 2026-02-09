variable "name" {
  description = "The display name of the project."
  type        = string
}

variable "project_id_prefix" {
  description = "Prefix for the project ID. Random suffix will be appended."
  type        = string
}

variable "folder_id" {
  description = "The ID of the folder to create the project in."
  type        = string
}

variable "billing_account" {
  description = "The billing account ID."
  type        = string
}

variable "environment" {
  description = "The environment this project belongs to (prod, non-prod, common, bootstrap)."
  type        = string
  validation {
    condition     = contains(["prod", "non-prod", "common", "bootstrap"], var.environment)
    error_message = "Environment must be one of: prod, non-prod, common, bootstrap."
  }
}

variable "labels" {
  description = "Map of labels to apply to the project. Must include cost_center and owner."
  type        = map(string)
  validation {
    condition     = can(var.labels["cost_center"]) && can(var.labels["owner"])
    error_message = "Labels must contain 'cost_center' and 'owner'."
  }
}

variable "apis" {
  description = "List of APIs to enable."
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "storage.googleapis.com"
  ]
}

variable "deletion_protection" {
  description = "Whether to protect the project from deletion."
  type        = bool
  default     = true
}
