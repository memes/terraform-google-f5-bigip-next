terraform {
  required_version = ">= 1.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.31"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.2"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }
}

data "google_compute_zones" "zones" {
  project = var.project_id
  region  = var.region
  status  = "UP"
}

data "http" "test_address" {
  url = "https://checkip.amazonaws.com"
  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Failed to get local IP address"
    }
  }
}

resource "random_shuffle" "zones" {
  input = data.google_compute_zones.zones.names
}

resource "random_pet" "prefix" {
  length = 1
  prefix = "tst"
  keepers = {
    project_id = var.project_id
  }
}

locals {
  prefix      = random_pet.prefix.id
  bigip_sa    = format("%s-bigip-next@%s.iam.gserviceaccount.com", local.prefix, var.project_id)
  bigip_cm_sa = format("%s-bigip-cm@%s.iam.gserviceaccount.com", local.prefix, var.project_id)
  labels = merge({
    purpose = "automated-testing"
    product = "terraform-google-f5-bigip-next"
    driver  = "kitchen-terraform"
  }, var.labels)
  test_source_cidrs = coalescelist(var.test_source_cidrs, [format("%s/32", trimspace(data.http.test_address.response_body))])
  ssh_pubkeys       = compact([for key in concat([tls_private_key.ssh.public_key_openssh], var.ssh_keys) : trimspace(key)])
  vpcs = {
    management = {
      primary   = "10.1.1.0/24"
      secondary = null
    }
    external = {
      primary   = "10.1.10.0/24"
      secondary = null
    }
    internal = {
      primary   = "10.1.20.0/24"
      secondary = null
    }
    ha = {
      primary   = "10.1.30.0/24"
      secondary = null
    }
  }
}

module "bigip_sa" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "4.1.1"
  project_id = var.project_id
  prefix     = local.prefix
  names = [
    "bigip-next",
    "bigip-cm",
  ]
  descriptions = [
    "BIG-IP Next automated testing account",
    "BIG-IP Next CM automated testing account",
  ]
  project_roles = formatlist("%s=>%s", var.project_id, [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
  ])
  generate_keys = false
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_privkey" {
  filename        = format("${path.module}/%s-ssh", local.prefix)
  file_permission = "0600"
  content         = tls_private_key.ssh.private_key_pem
}

resource "local_file" "ssh_pubkey" {
  filename        = format("${path.module}/%s-ssh.pub", local.prefix)
  file_permission = "0644"
  content         = tls_private_key.ssh.public_key_openssh
}

module "vpcs" {
  for_each                               = local.vpcs
  source                                 = "terraform-google-modules/network/google"
  version                                = "5.2.0"
  project_id                             = var.project_id
  network_name                           = format("%s-%s", local.prefix, each.key)
  description                            = format("BIG-IP Next testing %s VPC", each.key)
  auto_create_subnetworks                = false
  delete_default_internet_gateway_routes = false
  mtu                                    = 1500
  routing_mode                           = "REGIONAL"
  subnets = [
    {
      subnet_name           = format("%s-%s", local.prefix, each.key)
      subnet_ip             = each.value.primary
      subnet_region         = var.region
      subnet_private_access = false
    }
  ]
  secondary_ranges = coalesce(each.value.secondary, "unspecified") == "unspecified" ? {} : {
    format("%s-%s", local.prefix, each.key) = [
      {
        range_name    = format("%s-%s-secondary", local.prefix, each.key)
        ip_cidr_range = each.value.secondary
      }
    ]
  }
}

module "bastion" {
  source     = "memes/private-bastion/google"
  version    = "2.0.2"
  project_id = var.project_id
  prefix     = local.prefix
  # TODO @memes - remove public IP addresses
  external_ip = true
  # VM will have public IP address; can use published proxy image
  proxy_container_image = "ghcr.io/memes/terraform-google-private-bastion/forward-proxy:2.0.2"
  zone                  = random_shuffle.zones.result[0]
  subnet                = module.vpcs["management"].subnets_self_links[0]
  labels                = local.labels
  bastion_targets = {
    priority = 900
    cidrs    = null
    tags     = null
    service_accounts = [
      local.bigip_sa,
      local.bigip_cm_sa,
    ]
  }
  depends_on = [
    module.vpcs,
  ]
}

# Add a firewall rule to management VPC to allow ingress from testing CIDRs to
# ports 22 and 5443.
resource "google_compute_firewall" "test_admin" {
  project       = var.project_id
  name          = format("%s-bip-admin", local.prefix)
  description   = format("BIG-IP Next administration (%s)", local.prefix)
  network       = module.vpcs["management"].network_self_link
  direction     = "INGRESS"
  source_ranges = local.test_source_cidrs
  target_service_accounts = [
    local.bigip_sa,
  ]
  allow {
    protocol = "tcp"
    ports = [
      22,
      5443,
    ]
  }
}

# Add a firewall rule to management VPC to allow ingress from testing CIDRs to
# port 443 on BIG-IP Next CM.
resource "google_compute_firewall" "test_cm_admin" {
  project       = var.project_id
  name          = format("%s-cm-admin", local.prefix)
  description   = format("BIG-IP Next CM administration (%s)", local.prefix)
  network       = module.vpcs["management"].network_self_link
  direction     = "INGRESS"
  source_ranges = local.test_source_cidrs
  target_service_accounts = [
    local.bigip_cm_sa,
  ]
  allow {
    protocol = "tcp"
    ports = [
      22,
      443,
    ]
  }
}

resource "local_file" "harness_tfvars" {
  filename = "${path.module}/harness.tfvars"
  content  = <<-EOC
    prefix = "${local.prefix}"
    project_id = "${var.project_id}"
    region = "${var.region}"
    bigip_sa = "${local.bigip_sa}"
    subnets = ${jsonencode({ for k, v in module.vpcs : k => v.subnets_self_links[0] })}
    EOC
}
