# IPAM (IP Address Management) Module
# Automatically allocates IP ranges from the master 10.0.0.0/16 block

locals {
  # Master IPAM configuration
  master_cidr = "10.1.0.0/16"
  
  # Environment base addresses (first octet after 10.1)
  environment_bases = {
    Common     = 0    # 10.1.0.0/18
    Prod       = 64   # 10.1.64.0/18
    PreProd    = 128  # 10.1.128.0/18
    NonProd    = 192  # 10.1.192.0/18
  }
  
  # Region offsets for primary subnets
  region_offsets = {
    "asia-south1"   = 0
    "us-central1"   = 1
    "europe-west1"  = 2
    "asia-east1"    = 3
    "us-east1"      = 4
  }
  
  # Primary Subnets (Dynamically read from ipam.csv)
  # The IPAM script assigns these dynamically based on environment Tier sizes,
  # so we scrape the truth directly from the CSV instead of using fixed math.
  all_allocations = csvdecode(file("${path.module}/../../ipam.csv"))
  
  # Filter to only primary subnets
  primary_allocs = [
    for alloc in local.all_allocations : alloc
    if alloc.Status == "Allocated" && alloc.Resource_Type == "Subnet"
  ]
  
  # Group by Environment -> Region -> CIDR string
  # Example: primary_subnet["Production"]["asia-south1"] = "10.0.64.0/22"
  primary_subnet = {
    for env in distinct([for a in local.primary_allocs : a.Environment]) : env => {
      for a in local.primary_allocs : a.Region => a.CIDR
      if a.Environment == env
    }
  }
  
  # GKE pod ranges (Dynamically read from ipam.csv)
  gke_pod_allocs = [
    for alloc in local.all_allocations : alloc
    if alloc.Status == "Allocated" && alloc.Resource_Type == "Secondary" && length(regexall("pods", alloc.Resource_Name)) > 0
  ]
  
  gke_pods = {
    for env in distinct([for a in local.gke_pod_allocs : a.Environment]) : env => {
      for a in local.gke_pod_allocs : a.Region => a.CIDR
      if a.Environment == env
    }
  }
  
  # GKE service ranges (Dynamically read from ipam.csv)
  gke_service_allocs = [
    for alloc in local.all_allocations : alloc
    if alloc.Status == "Allocated" && alloc.Resource_Type == "Secondary" && length(regexall("services", alloc.Resource_Name)) > 0
  ]
  
  gke_services = {
    for env in distinct([for a in local.gke_service_allocs : a.Environment]) : env => {
      for a in local.gke_service_allocs : a.Region => a.CIDR
      if a.Environment == env
    }
  }
  
}

# Outputs for easy reference
output "ipam_primary_subnets" {
  description = "All available primary subnet allocations"
  value       = local.primary_subnet
}

output "ipam_gke_pods" {
  description = "All available GKE pod range allocations"
  value       = local.gke_pods
}

output "ipam_gke_services" {
  description = "All available GKE service range allocations"
  value       = local.gke_services
}


