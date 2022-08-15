variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "test_source_cidrs" {
  type    = list(string)
  default = []
}

variable "ssh_keys" {
  type    = list(string)
  default = []
}
