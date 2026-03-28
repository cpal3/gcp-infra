output "load_balancer_ips" {
  description = "Internal IP addresses of the deployed Load Balancers."
  value = {
    for k, v in module.load_balancer : k => v.forward_rule_ip
  }
}

output "cloud_run_uris" {
  description = "URIs of the deployed Cloud Run services."
  value = {
    for k, v in module.cloud_run : k => v.service_uri
  }
}

output "testing_vms" {
  description = "Names and locations of the testing VMs."
  value = {
    for k, v in module.vm : k => v.instance_name
  }
}
