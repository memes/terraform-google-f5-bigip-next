output "self_links" {
  value       = module.bigip.self_links
  description = <<-EOD
A list of BIG-IP Next afully-qualified self-links.
EOD
}

output "instance_addresses" {
  value       = module.bigip.instance_addresses
  description = <<-EOD
  A map of instance name to assigned private IP addresses and alias CIDRs on each interface.
  EOD
}

output "instance_public_addresses" {
  value       = module.bigip.instance_public_addresses
  description = <<-EOD
  A map of instance name to external public IP addresses on each interface.
  EOD
}
