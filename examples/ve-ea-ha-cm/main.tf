terraform {
  required_version = ">= 1.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.31"
    }
  }
}

# TODO @memes - what is the correct way to handle the floating ip assignments of
# an HA pair? TBD

# Create a pair of BIG-IP Next VMs with fixed IP address offsets within the CIDRs
module "bigip" {
  source          = "../../../"
  project_id      = var.project_id
  name            = var.name
  image           = var.bigip_next_image
  labels          = var.labels
  service_account = var.bigip_next_service_account
  subnets         = var.subnets
  ip_assignments = [
    {
      offsets         = [7, 77]
      floating_offset = 9
    },
    {
      offsets         = [8, 88]
      floating_offset = null
    }
  ]
}

# Create a single BIG-IP CM VM with fixed IP address offset within the management CIDR
module "cm" {
  source          = "../../../modules/cm/"
  project_id      = var.project_id
  name            = var.name
  image           = var.bigip_cm_image
  labels          = var.labels
  service_account = var.bigip_cm_service_account
  subnets = {
    management = var.subnets.management
  }
  ip_assignments = [
    {
      offsets         = [5]
      floating_offset = null
    },
  ]
  bigip_next_service_account = var.bigip_next_service_account
}
