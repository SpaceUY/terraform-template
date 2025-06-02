variable "project" {
  type        = string
  nullable    = false
  description = "Project name"
}

variable "region" {
  type        = string
  nullable    = false
  description = "Region to deploy VPC in"
}

variable "frontend_domain" {
  type        = string
  nullable    = false
  description = "domain url for frontend"
}

variable "backend_domain" {
  type = string
  nullable = false
  description = "domain url for backend"
}

variable "frontend_acm_arn" {
  type        = string
  nullable    = false
  description = "ARN of the Certificate for SSL"
}

variable "secured" {
  type        = bool
  default     = true
  description = "Controls access to some resources. Only set to false during initial setup"
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
}

variable "task_memory" {
  type    = number
  default = 512
}

variable "backend_acm_arn" {
  type     = string
  nullable = false
}

variable "cloudfront_price_class" {
  type = string
  default = "PriceClass_100"
  description = "Price class for Cloudfront to use. See https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PriceClass.html for more info"

  validation {
    condition = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.cloudfront_price_class)
    error_message = "Cloudfront_price_class must be one of the valid price classes."
  }
}

variable "db_size" {
  type = string
  default = "db.t4g.medium"
}
