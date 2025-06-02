terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.66.0"
    }
  }

  backend "s3" {
    key = "terraform.tfstate"
    profile = var.project
  }
}

provider "aws" {
  region = var.region
  profile = var.project

  default_tags {
    tags = {
      "Managed By" = "Terraform"
      Project      = var.project
      Workspace    = terraform.workspace
    }
  }
}

locals {
  name_prefix = "${var.project}--${terraform.workspace}"
}

module "deploy_user" {
  source = "../modules/iam-user"
  prefix = "${local.name_prefix}--deploy"
}

module "frontend" {
  source = "../modules/static-frontend"
  prefix = local.name_prefix
  region = var.region
  domain = var.frontend_domain
  acm_arn = var.frontend_acm_arn
  iam_deploying_user_name = module.deploy_user.user_name
}
