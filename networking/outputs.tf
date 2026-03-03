output "vpc_networks" {
  description = "Map of VPC network details"
  value = {
    for k, v in module.vpcs : k => {
      network_name        = v.network_name
      network_id          = v.network_id
      is_shared_vpc_host  = v.is_shared_vpc_host
      subnets             = v.subnets
    }
  }
}

output "peering_connections" {
  description = "VPC peering connection names"
  value = {
    for k, v in google_compute_network_peering.peerings : k => v.name
  }
}
