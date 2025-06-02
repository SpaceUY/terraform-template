variable "create" {
  type = bool
  default = true
  description = "Whether to create the IAM user"
}

variable "prefix" {
  type = string
  nullable = false
  description = "Prefix for the IAM user"
}
