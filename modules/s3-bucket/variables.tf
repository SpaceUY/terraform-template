variable "create" {
  type = bool
  default = true
  description = "Whether to create the S3 bucket"
}

variable "prefix" {
  type = string
  description = "Prefix for the S3 bucket name"
}

variable "acl" {
  type = string
  description = "ACL for the S3 bucket"
  default = "private"
}

variable "ecs_task_execution_role_name" {
  type = string
  description = "Name of the ECS task execution role"
}