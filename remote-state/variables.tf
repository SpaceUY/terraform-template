variable "project" {
  type        = string
  nullable    = false
  description = "Project name"
}

variable "region" {
  type        = string
  nullable    = false
  description = "Region to deploy remote state in"
  default = "us-east-1"
}