terraform {
  required_version = ">= 1.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.31"
    }
  }
}

# Validate that each subnet self-link resolves to a VPC subnet
data "google_compute_subnetwork" "management" {
  self_link = var.subnets.management
}

data "google_compute_zones" "zones" {
  project = var.project_id
  region  = local.region
  status  = "UP"
}

locals {
  region = element(distinct([
    data.google_compute_subnetwork.management.region,
  ]), 0)
}

resource "google_compute_instance" "cm" {
  for_each = { for i, assignment in var.ip_assignments : format("%s-big-ip-cm-%02d", var.name, i + 1) => {
    ip_offsets         = assignment.offsets
    floating_ip_offset = assignment.floating_offset
    zone               = element(data.google_compute_zones.zones.names, i)
  } }
  project     = var.project_id
  name        = each.key
  description = "BIG-IP Next CM testing instance (%s)"
  zone        = each.value.zone
  labels      = var.labels
  metadata = merge({
    # TODO @memes - remove? SSH via metadata keys seems to work consistently
    serial-port-enable = "TRUE"
  }, var.metadata)
  machine_type     = var.machine_type
  min_cpu_platform = var.min_cpu_platform

  service_account {
    email = var.service_account
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  scheduling {
    automatic_restart = true
    preemptible       = false
  }

  # advanced_machine_features {
  #   enable_nested_virtualization = false
  #   threads_per_core             = null
  # }

  boot_disk {
    auto_delete = true
    initialize_params {
      # image = coalesce(var.image, data.google_compute_image.bigip.self_link)
      image = var.image
      type  = "pd-balanced"
    }
  }

  tags           = var.tags
  can_ip_forward = true

  # First nic will be attached to the control-plane network.
  network_interface {
    subnetwork = data.google_compute_subnetwork.management.self_link
    network_ip = length(each.value.ip_offsets) > 0 ? cidrhost(data.google_compute_subnetwork.management.ip_cidr_range, each.value.ip_offsets[0]) : null
    nic_type   = "VIRTIO_NET"
    stack_type = "IPV4_ONLY"
    dynamic "alias_ip_range" {
      for_each = toset(compact(concat(length(each.value.ip_offsets) > 1 ? slice(each.value.ip_offsets, 1, length(each.value.ip_offsets)) : [], [each.value.floating_ip_offset])))
      content {
        ip_cidr_range = format("%s/32", cidrhost(data.google_compute_subnetwork.management.ip_cidr_range, alias_ip_range.value))
      }
    }
    # TODO @memes - Public NAT'd address added to control-plane interface to avoid
    # use of Cloud NAT, IAP bastion, etc.
    access_config {}
  }
}

# Add a firewall rule to the management VPC network to allow all inbound traffic
# between BIG-IP Next CM instances.
resource "google_compute_firewall" "ha" {
  project     = var.project_id
  name        = format("%s-cm-ha", var.name)
  description = format("BIG-IP Next CM instance-to-instance (%s)", var.name)
  network     = data.google_compute_subnetwork.management.network
  direction   = "INGRESS"
  target_service_accounts = [
    var.service_account,
  ]
  source_service_accounts = [
    var.service_account,
  ]
  # TODO @memes - what is the correct set of protocols and ports for CM HA?
  allow {
    protocol = "all"
  }
}

# Add a firewall rule to management VPC network to allow all inbound traffic between
# BIG-IP CM and BIG-IP Next instances.
resource "google_compute_firewall" "cm_bigip" {
  project     = var.project_id
  name        = format("%s-bip-cm", var.name)
  description = format("BIG-IP CM and BIG-IP Next communication (%s)", var.name)
  network     = data.google_compute_subnetwork.management.network
  direction   = "INGRESS"
  target_service_accounts = [
    var.service_account,
    var.bigip_next_service_account,
  ]
  source_service_accounts = [
    var.service_account,
    var.bigip_next_service_account,
  ]
  # TODO @memes - what is the correct set of protocols and ports for CM and BIG-IP?
  allow {
    protocol = "all"
  }
}
