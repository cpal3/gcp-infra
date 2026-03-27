variable "project_id" {
  description = "The project ID to create the network in."
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network."
  type        = string
}

variable "routing_mode" {
  description = "Network routing mode (REGIONAL or GLOBAL)."
  type        = string
  default     = "REGIONAL"
}

variable "enable_shared_vpc_host" {
  description = "Enable this project as a Shared VPC host."
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs on subnets."
  type        = bool
  default     = false
}

variable "subnets" {
  description = "List of subnets to create."
  type = list(object({
    name                  = string
    cidr                  = string
    region                = string
    private_google_access = optional(bool, true)
    secondary_ranges      = optional(list(object({ name = string, cidr = string })), [])
  }))
}

variable "private_service_access_configs" {
  description = "List of private service access configurations (reserved IP ranges for Google services)."
  type = list(object({
    name          = string
    address       = string
    prefix_length = number
  }))
  default = []
}
