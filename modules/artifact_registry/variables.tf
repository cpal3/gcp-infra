variable "project_id" {
  description = "The project ID to create the repository in"
  type        = string
}

variable "region" {
  description = "The region to create the repository in"
  type        = string
}

variable "repo_id" {
  description = "The ID of the repository"
  type        = string
}

variable "format" {
  description = "The format of the repository (DOCKER, MAVEN, etc.)"
  type        = string
  default     = "DOCKER"
}

variable "labels" {
  description = "Labels to apply to the repository"
  type        = map(string)
  default     = {}
}
