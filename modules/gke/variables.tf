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

variable "network_id" {
  description = "The VPC network ID."
  type        = string
}

variable "subnetwork_id" {
  description = "The subnetwork ID."
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the node pool."
  type        = number
  default     = 1
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

variable "labels" {
  description = "A map of labels to apply to resources."
  type        = map(string)
  default     = {}
}
