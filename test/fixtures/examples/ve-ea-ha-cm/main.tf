terraform {
  required_version = ">= 1.2"
}

locals {
  prefix = format("%s-%s", var.prefix, var.test_prefix)
}

module "test" {
  source                     = "./../../../ephemeral/ve-ea-ha-cm/"
  project_id                 = var.project_id
  name                       = local.prefix
  bigip_next_image           = var.image
  bigip_cm_image             = var.cm_image
  labels                     = var.labels
  bigip_next_service_account = var.bigip_sa
  bigip_cm_service_account   = var.bigip_cm_sa
  subnets                    = var.subnets
}
