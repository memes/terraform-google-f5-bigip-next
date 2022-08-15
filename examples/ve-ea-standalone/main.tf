terraform {
  required_version = ">= 1.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.31"
    }
  }
}

# Create a single standalone BIG-IP Next VM with fixed IP address offset within the CIDRs
module "bigip" {
  source          = "../../../"
  project_id      = var.project_id
  name            = var.name
  image           = var.image
  labels          = var.labels
  service_account = var.service_account
  subnets         = var.subnets
  ip_assignments = [
    {
      offsets         = [7, 77]
      floating_offset = null
    },
  ]
}
