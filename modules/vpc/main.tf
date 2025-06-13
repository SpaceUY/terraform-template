## VPC and Subnet CIDR mapping
#
#       10 .           ? .                    ? .        ?
# 00001010   000000 | 00   000 |   00  |   000  | 00000000
#     VPC Network   |  Region  | Group | Subnet |   Hosts
#                   |      25  |     4 |      9 | 255 - 5 = 250
#
# (Subnet) Groups - 0: public | 1: private | 2: intra | 3: database 




locals {
  vpc_cidr              = cidrsubnet("10.0.0.0/14", 5, var.region_number[var.region])
  public_subnets_cidr   = cidrsubnet(local.vpc_cidr, 2, 0)
  database_subnets_cidr = cidrsubnet(local.vpc_cidr, 2, 3)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "${var.prefix}--vpc"
  azs  = data.aws_availability_zones.available.names
  cidr = local.vpc_cidr
  

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = true
  one_nat_gateway_per_az = false

  # enable_ipv6                     = true
  # assign_ipv6_address_on_creation = true

  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = var.publicly_accessible_database

  create_egress_only_igw = false

  public_subnets = [
    cidrsubnet(local.public_subnets_cidr, 3, 0),
    cidrsubnet(local.public_subnets_cidr, 3, 1),
    cidrsubnet(local.public_subnets_cidr, 3, 2),
  ]
  database_subnets = [
    cidrsubnet(local.database_subnets_cidr, 3, 0),
    cidrsubnet(local.database_subnets_cidr, 3, 1),
    cidrsubnet(local.database_subnets_cidr, 3, 2),
  ]
}
