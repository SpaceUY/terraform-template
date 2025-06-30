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


module "vpc" {
  source = "../modules/vpc"
  prefix = local.name_prefix
  region = var.region
}

module "deploy_user" {
  source = "../modules/iam-user"
  prefix = "${local.name_prefix}--deploy"
}

module "frontend" {
  source = "../modules/static-frontend"
  prefix = local.name_prefix
  domain = var.frontend_domain
  acm_arn = var.frontend_acm_arn
  iam_deploying_user_name = module.deploy_user.user_name
}

module "backend" {
  source = "../modules/ecs-backend"
  prefix = local.name_prefix
  iam_deploying_user_name = module.deploy_user.user_name
  vpc_id = module.vpc.vpc_id
  vpc_cidr_block = module.vpc.vpc_cidr_block
  vpc_public_subnets = module.vpc.public_subnets
  acm_arn = var.backend_acm_arn
}

module "database" {
  source = "../modules/database"
  prefix = local.name_prefix
  vpc_id = module.vpc.vpc_id
  vpc_cidr_block = module.vpc.vpc_cidr_block
  db_subnet_group_name = module.vpc.database_subnet_group_name
}

