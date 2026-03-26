variable "service_name" {
  description = "The name of the Cloud Run service."
  type        = string
}

variable "project_id" {
  description = "The project ID."
  type        = string
}

variable "region" {
  description = "The region to deploy the service into."
  type        = string
}

variable "image" {
  description = "The container image to deploy."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "network_id" {
  description = "The VPC network ID for egress."
  type        = string
}

variable "subnetwork_id" {
  description = "The subnetwork ID for egress."
  type        = string
}

variable "labels" {
  description = "A map of labels to apply to resources."
  type        = map(string)
  default     = {}
}
