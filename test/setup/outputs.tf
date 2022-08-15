output "harness_tfvars" {
  value = abspath(local_file.harness_tfvars.filename)
}

output "ssh_privkey_path" {
  value = abspath(local_file.ssh_privkey.filename)
}

output "ssh_pubkey_path" {
  value = abspath(local_file.ssh_pubkey.filename)
}

output "ssh_pubkeys" {
  value = local.ssh_pubkeys
}

output "bigip_cm_sa" {
  value = local.bigip_cm_sa
}

output "tunnel_command" {
  value = module.bastion.tunnel_command
}
