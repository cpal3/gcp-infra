variable "org_id" {
  description = "The Organization ID."
  type        = string
}

variable "billing_account" {
  description = "The Billing Account ID."
  type        = string
}

variable "region" {
  description = "The region for resources."
  type        = string
}

variable "project_id_prefix" {
  description = "Prefix for project IDs."
  type        = string
}

variable "cost_center" {
  description = "Cost center for billing labels."
  type        = string
}

variable "owner" {
  description = "Owner for project labels."
  type        = string
}
