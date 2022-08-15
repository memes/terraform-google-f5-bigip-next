terraform {
  required_version = ">= 1.2"
}

locals {
  prefix = format("%s-%s", var.prefix, var.test_prefix)
}

module "test" {
  source          = "./../../../ephemeral/ve-ea-standalone/"
  project_id      = var.project_id
  name            = local.prefix
  image           = var.image
  labels          = var.labels
  service_account = var.bigip_sa
  subnets         = var.subnets
}
