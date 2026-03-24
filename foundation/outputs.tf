output "project_ids" {
  description = "Map of project names to project IDs"
  value = {
    for k, v in module.projects : k => v.project_id
  }
}

output "folder_ids" {
  description = "Map of folder names to folder IDs"
  value       = module.folders.ids
}

output "vpc_networks" {
  description = "Map of VPC network details"
  value = {
    for k, v in module.vpcs : k => {
      network_name       = v.network_name
      network_id         = v.network_id
      is_shared_vpc_host = v.is_shared_vpc_host
      subnets            = v.subnets
    }
  }
}
