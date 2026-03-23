variable "host_project_id" {
  description = "The ID of the host Shared VPC project."
  type        = string
}

variable "service_project_id" {
  description = "The ID of the service project to attach to the Shared VPC host."
  type        = string
}

variable "subnetwork" {
  description = "The name of the subnetwork in the host project to grant access to. If provided, subnet_users will be granted compute.networkUser role."
  type        = string
  default     = ""
}

variable "region" {
  description = "The region of the subnetwork."
  type        = string
  default     = ""
}

variable "subnet_users" {
  description = "List of IAM members (e.g., serviceAccount:foo@., user:bar@.) to grant compute.networkUser role on the subnetwork."
  type        = list(string)
  default     = []
}
