variable "create" {
  type        = bool
  default     = true
  description = "Whether to create the static frontend resources"
}

variable "prefix" {
  type = string
  nullable = false
  description = "Prefix for the static frontend resources"
}

variable "region" {
  type = string
  nullable = false
  description = "Region for the static frontend resources"
}

variable "domain" {
  type        = string
  nullable    = false
  description = "domain url for the static frontend resources"
}

variable "acm_arn" {
  type        = string
  nullable    = false
  description = "ARN of the Certificate for SSL"
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

variable "iam_deploying_user_name" {
  type = string
  nullable = false
  description = "Name of the IAM user to be given permissions to deploy to the static frontend resources"
}