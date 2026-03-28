variable "project_id" {
  description = "The project ID."
  type        = string
}

variable "region" {
  description = "The region to deploy the VM into."
  type        = string
}

variable "zone" {
  description = "The zone to deploy the VM into."
  type        = string
  default     = "asia-south1-a"
}

variable "instance_name" {
  description = "The name of the compute instance."
  type        = string
}

variable "machine_type" {
  description = "The machine type for the instance."
  type        = string
  default     = "e2-micro"
}

variable "network_id" {
  description = "The VPC network ID."
  type        = string
}

variable "subnetwork_id" {
  description = "The subnetwork ID."
  type        = string
}

variable "labels" {
  description = "A map of labels to apply to resources."
  type        = map(string)
  default     = {}
}
