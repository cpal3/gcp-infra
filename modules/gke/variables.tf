variable "cluster_name" {
  description = "The name of the GKE cluster."
  type        = string
}

variable "project_id" {
  description = "The project ID."
  type        = string
}

variable "region" {
  description = "The region to deploy the cluster into."
  type        = string
}

variable "regional" {
  description = "Whether to create a regional cluster."
  type        = bool
  default     = true
}

variable "zones" {
  description = "The zones to use for the cluster or node pool."
  type        = list(string)
  default     = []
}

variable "network_id" {
  description = "The VPC network ID."
  type        = string
}

variable "subnetwork_id" {
  description = "The subnetwork ID."
  type        = string
}

variable "node_count" {
  description = "Initial number of nodes in the node pool."
  type        = number
  default     = 1
}

variable "min_node_count" {
  description = "Minimum number of nodes for autoscaling."
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes for autoscaling."
  type        = number
  default     = 5
}

variable "enable_autoscaling" {
  description = "Whether to enable node pool autoscaling."
  type        = bool
  default     = true
}

variable "enable_nap" {
  description = "Whether to enable Node Auto-Provisioning (NAP)."
  type        = bool
  default     = true
}

variable "enable_network_policy" {
  description = "Whether to enable GKE network policy."
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Whether to disable the public endpoint of the cluster."
  type        = bool
  default     = true
}

variable "machine_type" {
  description = "Machine type for the nodes."
  type        = string
  default     = "e2-medium"
}

variable "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation to use for the hosted master network."
  type        = string
}

variable "ip_range_pods" {
  description = "The secondary IP range to use for pods."
  type        = string
}

variable "ip_range_services" {
  description = "The secondary IP range to use for services."
  type        = string
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection for the cluster."
  type        = bool
  default     = false
}

variable "labels" {
  description = "A map of labels to apply to resources."
  type        = map(string)
  default     = {}
}

variable "release_channel" {
  description = "GKE release channel (UNSPECIFIED, RAPID, REGULAR, STABLE)."
  type        = string
  default     = "REGULAR"
}

variable "master_authorized_networks" {
  description = "List of master authorized networks."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "enable_fleet_registration" {
  description = "Whether to register the cluster in the GKE Fleet (Hub) for Connect Gateway."
  type        = bool
  default     = false
}

