output "self_links" {
  value       = module.test.self_links
  description = <<-EOD
  A list of self-links of the BIG-IP instances.
  EOD
}

output "instance_addresses" {
  value       = module.test.instance_addresses
  description = <<-EOD
  A map of instance name to assigned private IP addresses and alias CIDRs on each interface.
  EOD
}

output "instance_public_addresses" {
  value       = module.test.instance_public_addresses
  description = <<-EOD
  A map of instance name to assigned IP addresses and alias CIDRs.
  EOD
}

output "cp_public_addresses" {
  value       = compact([for k, v in module.test.instance_public_addresses : length(v["management"]) > 0 ? v["management"][0] : ""])
  description = <<-EOD
  A list of the primary internal IP addresses assigned on the management interfaces.
  EOD
}
