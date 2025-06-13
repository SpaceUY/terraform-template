variable "create" {
  type        = bool
  default     = true
  description = "Whether to create the ecs backend resources"
}

variable "prefix" {
  type = string
  nullable = false
  description = "Prefix for the ecs backend resources"
}

variable "secrets" {
  type = map(string)
  nullable = true
  default = {}
  description = "Secrets for the ecs backend"
}

variable "task_port_mappings" {
  type = list(object({
    containerPort = number
    hostPort      = number
  }))
  default = [{
    containerPort = 5000
    hostPort      = 5000
  }]
  description = "ECS Task port mappings"
}

variable "container_port" {
  type        = number
  nullable    = false
  default = 5000
  description = "Port exposed by container to reach running process"
}

variable "task_cpu" {
  type    = number
  default = 256
  description = "CPU for the ecs task"
}

variable "task_memory" {
  type    = number
  default = 512
  description = "Memory for the ecs task"
}

variable "vpc_id" {
  type = string
  nullable = false
  description = "VPC ID"
}

variable "vpc_cidr_block" {
  type = string
  nullable = false
  description = "VPC CIDR block"
}

variable "vpc_public_subnets" {
  type = list(string)
  nullable = false
  description = "Public subnets for the vpc"
}

variable "acm_arn" {
  type = string
  nullable = false
  description = "ACM ARN"
}

variable "iam_deploying_user_name" {
  type = string
  nullable = false
  description = "Name of the IAM user to be given permissions to deploy to the ecs backend resources"
}





