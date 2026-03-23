# Centralized Provider Version Configuration
# This file defines the required Terraform and provider versions for all layers.
# Include this file in each layer (bootstrap, foundation, networking) to ensure consistency.

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.45.0"  # Pinned to avoid v6.50.0 crashes
    }
  }
}
