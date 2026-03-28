variable "lb_name" {
  description = "The name of the load balancer."
  type        = string
}

variable "project_id" {
  description = "The project ID."
  type        = string
}

variable "region" {
  description = "The region to deploy the LB into."
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

variable "labels" {
  description = "A map of labels to apply to resources."
  type        = map(string)
  default     = {}
}

variable "serverless_neg_id" {
  description = "The ID of the Serverless NEG for the backend."
  type        = string
  default     = null
}
