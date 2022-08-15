output "self_links" {
  value       = [for vm in google_compute_instance.cm : vm.self_link]
  description = <<-EOD
  A list of self-links of the BIG-IP instances.
  EOD
}

output "instance_addresses" {
  value = { for vm in google_compute_instance.cm : vm.name => {
    management = concat([vm.network_interface[0].network_ip], [for alias in vm.network_interface[0].alias_ip_range : alias.ip_cidr_range])
  } }
  description = <<-EOD
  A map of instance name to assigned private IP addresses and alias CIDRs on each interface.
  EOD
}

output "instance_public_addresses" {
  value = { for vm in google_compute_instance.cm : vm.name => {
    management = compact([for access_config in vm.network_interface[0].access_config : access_config.nat_ip])
  } }
  description = <<-EOD
  A map of instance name to external public IP addresses on each interface.
  EOD
}
