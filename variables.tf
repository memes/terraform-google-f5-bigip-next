variable "project_id" {
  type = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "The project_id variable must be 6 to 30 lowercase letters, digits, or hyphens; it must start with a letter and cannot end with a hyphen."
  }
  description = <<-EOD
  The GCP project identifier where the cluster will be created.
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
  A fully-qualified Compute Engine image or family name to use with the instances.
  Must be of the format `projects/project-id/global/images/image-name` or
  `projects/project-id/global/images/family/family-name`.
  EOD
}

variable "metadata" {
  type        = map(string)
  default     = {}
  description = <<-EOD
  An optional map of metadata values that will be applied to the instances. Use
  this to add user-data configuration, for example.
  EOD
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = <<-EOD
  An optional map of *labels* to add to the instances.
  EOD
}

variable "tags" {
  type        = list(string)
  default     = []
  description = <<-EOD
  An optional list of *network tags* to add to the instances.
  EOD
}

variable "min_cpu_platform" {
  type        = string
  default     = null
  description = <<-EOD
  An optional constraint used when scheduling the BIG-IP VMs; this value prevents
  the VMs from being scheduled on hardware that doesn't meet the minimum CPU
  micro-architecture, and if specified it must be compatible with the value of
  'machine-type'. Default value is empty.
  EOD
}

variable "machine_type" {
  type        = string
  default     = "e2-standard-8"
  description = <<-EOD
  The machine type to use for BIG-IP VMs; this may be a standard GCE machine type,
  or a customised VM ('custom-VCPUS-MEM_IN_MB'). Default value is 'e2-standard-8'.
  EOD
}

variable "service_account" {
  type = string
  validation {
    condition     = can(regex("(?:[a-z][a-z0-9-]{4,28}[a-z0-9]@[a-z][a-z0-9-]{4,28}\\.iam|[1-9][0-9]+-compute@developer)\\.gserviceaccount\\.com$", var.service_account))
    error_message = "The service_account variable must be a valid GCP service account email address."
  }
  description = <<-EOD
  The service account that will be used for the BIG-IP VMs.
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
  Fully-qualified subnet self-links for each VPC network that BIG-IP Next instances
  will be attached to.
  EOD
}

variable "ip_assignments" {
  type = list(object({
    offsets         = list(number)
    floating_offset = number
  }))
  validation {
    condition     = length(concat([for assignment in var.ip_assignments : length(assignment.offsets) > 0 && length(compact([for offset in assignment.offsets : offset >= 0 && floor(offset) == offset ? "x" : ""])) == length(assignment.offsets) && (assignment.floating_offset == null ? true : (assignment.floating_offset >= 0 && floor(assignment.floating_offset) == assignment.floating_offset)) ? "x" : ""])) == length(var.ip_assignments)
    error_message = "The ip_assignments entries must each contain one or more integer offset values, and either a null or integer floating_offset value."
  }
  default = [
    {
      offsets         = []
      floating_offset = null
    },
    {
      offsets         = []
      floating_offset = null
    }
  ]
}
