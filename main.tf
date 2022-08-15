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

data "google_compute_subnetwork" "external" {
  self_link = var.subnets.external
}

data "google_compute_subnetwork" "internal" {
  self_link = var.subnets.internal
}

data "google_compute_subnetwork" "ha" {
  self_link = var.subnets.ha
}

data "google_compute_zones" "zones" {
  project = var.project_id
  region  = local.region
  status  = "UP"
}

locals {
  region = element(distinct([
    data.google_compute_subnetwork.management.region,
    data.google_compute_subnetwork.external.region,
    data.google_compute_subnetwork.internal.region,
    data.google_compute_subnetwork.ha.region,
  ]), 0)
}

resource "google_compute_instance" "bigip" {
  for_each = { for i, assignment in var.ip_assignments : format("%s-big-ip-next-%02d", var.name, i + 1) => {
    ip_offsets         = assignment.offsets
    floating_ip_offset = assignment.floating_offset
    zone               = element(data.google_compute_zones.zones.names, i)
  } }
  project     = var.project_id
  name        = each.key
  description = "BIG-IP Next testing instance (%s)"
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

  # Second and third NIC will be data-plane networks.
  network_interface {
    subnetwork = data.google_compute_subnetwork.external.self_link
    network_ip = length(each.value.ip_offsets) > 0 ? cidrhost(data.google_compute_subnetwork.external.ip_cidr_range, each.value.ip_offsets[0]) : null
    nic_type   = "VIRTIO_NET"
    stack_type = "IPV4_ONLY"
    dynamic "alias_ip_range" {
      for_each = toset(compact([each.value.floating_ip_offset]))
      content {
        ip_cidr_range = format("%s/32", cidrhost(data.google_compute_subnetwork.external.ip_cidr_range, alias_ip_range.value))
      }
    }
  }
  network_interface {
    subnetwork = data.google_compute_subnetwork.internal.self_link
    network_ip = length(each.value.ip_offsets) > 0 ? cidrhost(data.google_compute_subnetwork.internal.ip_cidr_range, each.value.ip_offsets[0]) : null
    nic_type   = "VIRTIO_NET"
    stack_type = "IPV4_ONLY"
    dynamic "alias_ip_range" {
      for_each = toset(compact([each.value.floating_ip_offset]))
      content {
        ip_cidr_range = format("%s/32", cidrhost(data.google_compute_subnetwork.internal.ip_cidr_range, alias_ip_range.value))
      }
    }
  }

  # Fourth interface is for HA data-plane
  network_interface {
    subnetwork = data.google_compute_subnetwork.ha.self_link
    network_ip = length(each.value.ip_offsets) > 0 ? cidrhost(data.google_compute_subnetwork.ha.ip_cidr_range, each.value.ip_offsets[0]) : null
    nic_type   = "VIRTIO_NET"
    stack_type = "IPV4_ONLY"
    dynamic "alias_ip_range" {
      for_each = toset(compact([each.value.floating_ip_offset]))
      content {
        ip_cidr_range = format("%s/32", cidrhost(data.google_compute_subnetwork.ha.ip_cidr_range, alias_ip_range.value))
      }
    }
  }
}

# Add a firewall rule to each VPC network to allow all inbound traffic between
# BIG-IP Next instances.
resource "google_compute_firewall" "ha" {
  for_each = {
    management = data.google_compute_subnetwork.management.network
    external   = data.google_compute_subnetwork.external.network
    internal   = data.google_compute_subnetwork.internal.network
    ha         = data.google_compute_subnetwork.ha.network
  }
  project     = var.project_id
  name        = format("%s-allow-bip-ha-%s", var.name, each.key)
  description = format("BIG-IP Next instance-to-instance (%s)", var.name)
  network     = each.value
  direction   = "INGRESS"
  target_service_accounts = [
    var.service_account,
  ]
  source_service_accounts = [
    var.service_account,
  ]
  # TODO @memes - what is the correct set of protocols and ports for HA?
  allow {
    protocol = "all"
  }
}
