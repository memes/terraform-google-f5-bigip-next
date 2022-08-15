terraform {
  required_version = ">= 1.2"
}

locals {
  prefix = format("%s-%s", var.prefix, var.test_prefix)
}

module "test" {
  source           = "./../../../"
  project_id       = var.project_id
  name             = local.prefix
  metadata         = var.metadata
  labels           = var.labels
  tags             = var.tags
  min_cpu_platform = var.min_cpu_platform
  machine_type     = var.machine_type
  service_account  = var.bigip_sa
  subnets          = var.subnets
  image            = var.image
  ip_assignments   = var.ip_assignments
}
