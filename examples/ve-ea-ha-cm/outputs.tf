output "self_links" {
  value       = concat(module.bigip.self_links, module.cm.self_links)
  description = <<-EOD
A list of BIG-IP Next and BIG-IP CM fully-qualified self-links.
EOD
}

output "instance_addresses" {
  value       = merge(module.bigip.instance_addresses, module.cm.instance_addresses)
  description = <<-EOD
  A map of instance name to assigned private IP addresses and alias CIDRs on each interface.
  EOD
}

output "instance_public_addresses" {
  value       = merge(module.bigip.instance_public_addresses, module.cm.instance_public_addresses)
  description = <<-EOD
  A map of instance name to external public IP addresses on each interface.
  EOD
}
