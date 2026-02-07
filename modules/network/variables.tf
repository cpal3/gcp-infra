variable "project_id" {
  description = "The project ID to create the network in."
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network."
  type        = string
}

variable "subnets" {
  description = "List of subnets to create."
  type = list(object({
    name             = string
    cidr             = string
    region           = string
    secondary_ranges = list(object({ name = string, cidr = string }))
  }))
}
