terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.66.0, < 5.0.0"
    }
  }
}

provider "aws" {
  region = var.region
  profile = var.project

  default_tags {
    tags = {
      "Managed By" = "Terraform"
      Project      = var.project
    }
  }
}

module "remote_state" {
  source = "nozaq/remote-state-s3-backend/aws"

  providers = {
    aws         = aws
    aws.replica = aws
  }

  enable_replication          = false
  terraform_iam_policy_create = false

  s3_bucket_name      = "${var.project}-remote-state"
  dynamodb_table_name = "${var.project}-remote-state-lock"
  kms_key_alias       = "${var.project}-remote-state-key"
}
