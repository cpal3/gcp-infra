variable "instance_name" {
  description = "The name of the database instance."
  type        = string
}

variable "project_id" {
  description = "The project ID."
  type        = string
}

variable "region" {
  description = "The region to deploy the DB into."
  type        = string
}

variable "database_version" {
  description = "The database version."
  type        = string
  default     = "POSTGRES_15"
}

variable "tier" {
  description = "The machine tier."
  type        = string
  default     = "db-f1-micro"
}

variable "network_id" {
  description = "The VPC network ID."
  type        = string
}

variable "allocated_ip_range" {
  description = "The allocated IP range name for Private Services Access."
  type        = string
  default     = null
}

variable "labels" {
  description = "A map of labels to apply to resources."
  type        = map(string)
  default     = {}
}
