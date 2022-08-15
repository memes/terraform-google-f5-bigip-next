variable "project_id" {
  type        = string
  description = <<-EOD
  The GCP project identifier where the BIG-IP Next and CM cluster will be created.
  EOD
}

variable "name" {
  type = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}[a-z0-9]$", var.name))
    error_message = "The name variable must be RFC1035 compliant and between 1 and 63 characters in length"
  }
  description = <<-EOD
  The name to use for generated resources.
  EOD
}

variable "image" {
  type = string
  validation {
    condition     = coalesce(var.image, "unspecified") == "unspecified" || can(regex("^(?:https://www.googleapis.com/compute/v1/)?projects/[a-z][a-z0-9-]{4,28}[a-z0-9]/global/images/(?:family/)?[a-z][a-z0-9-]{0,61}[a-z0-9]$", var.image))
    error_message = "The image variable must be a reference to a valid image or family, with project identifier."
  }
  description = <<-EOD
  A fully-qualified Compute Engine image or family name to use for BIG-IP Next instances.
  Must be of the format `projects/project-id/global/images/image-name` or
  `projects/project-id/global/images/family/family-name`.
  EOD
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = <<-EOD
  An optional map of *labels* to add to the instances.
  EOD
}

variable "service_account" {
  type = string
  validation {
    condition     = can(regex("(?:[a-z][a-z0-9-]{4,28}[a-z0-9]@[a-z][a-z0-9-]{4,28}\\.iam|[1-9][0-9]+-compute@developer)\\.gserviceaccount\\.com$", var.service_account))
    error_message = "The service_account variable must be a valid GCP service account email address."
  }
  description = <<-EOD
  The service account that will be used for the BIG-IP Next VMs.
  EOD
}

variable "subnets" {
  type = object({
    management = string
    external   = string
    internal   = string
    ha         = string
  })
  validation {
    condition     = length(compact([for subnet in values(var.subnets) : can(regex("^https://www.googleapis.com/compute/v1/projects/[a-z][a-z0-9-]{4,28}[a-z0-9]/regions/[a-z][a-z-]+[0-9]/subnetworks/[a-z]([a-z0-9-]+[a-z0-9])?$", subnet)) ? "x" : ""])) == 4
    error_message = "Each subnets value must be a fully-qualified self-link URI."
  }
  description = <<-EOD
  Fully-qualified subnet self-links for each VPC network that BIG-IP Next
  instances will be attached to.
  EOD
}
