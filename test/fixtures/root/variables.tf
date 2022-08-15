variable "test_prefix" {
  type = string
}

variable "prefix" {
  type = string
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "bigip_sa" {
  type = string
}

variable "subnets" {
  type = object({
    management = string
    external   = string
    internal   = string
    ha         = string
  })
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "tags" {
  type    = list(string)
  default = []
}

variable "min_cpu_platform" {
  type    = string
  default = null
}

variable "machine_type" {
  type    = string
  default = "e2-standard-8"
}

variable "metadata" {
  type    = map(string)
  default = {}
}

variable "image" {
  type    = string
  default = null
}

variable "ip_assignments" {
  type = list(object({
    offsets         = list(number)
    floating_offset = number
  }))
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

variable "verify_files" {
  type    = list(string)
  default = null
}
