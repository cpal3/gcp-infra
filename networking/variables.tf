variable "prod_folder_id" {
  description = "The ID of the Prod folder."
  type        = string
}

variable "non_prod_folder_id" {
  description = "The ID of the Non-Prod folder."
  type        = string
}

variable "billing_account" {
  description = "Billing account ID."
  type        = string
}

variable "region" {
  description = "Default region."
  type        = string
  default     = "us-central1"
}
