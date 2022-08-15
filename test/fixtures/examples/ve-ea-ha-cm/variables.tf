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

variable "bigip_cm_sa" {
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

variable "image" {
  type    = string
  default = null
}

variable "cm_image" {
  type    = string
  default = null
}
