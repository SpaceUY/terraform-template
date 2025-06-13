variable "prefix" {
  type = string
  nullable = false
  description = "Prefix for the VPC"
}

variable "use_default_vpc" {
  type = bool
  default = false
  description = "Whether to use the default VPC"
}

variable "region" {
  type = string
  nullable = false
  description = "Region for the VPC"
}

variable "publicly_accessible_database" {
  type = bool
  default = false
  description = "Whether to open an internet gateway to the database subnets"
}

