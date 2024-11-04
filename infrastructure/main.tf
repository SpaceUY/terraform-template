terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.66.0"
    }
  }

  backend "s3" {
    key = "terraform.tfstate"
    profile = "phenompoker"
  }
}

provider "aws" {
  region = var.region
  profile = "phenompoker"

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
  name_prefix_gs = "${var.project}-gameserver--${terraform.workspace}"
}
