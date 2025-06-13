# Rarely will need to set this variable
variable "region_number" {
  # Arbitrary mapping of region name to number to use in
  # a VPC's CIDR prefix.
  default = {
    us-east-1      = 1
    us-east-2      = 2
    us-west-1      = 3
    us-west-2      = 4
    af-south-1     = 5
    ap-east-1      = 6
    ap-south-1     = 7
    ap-northeast-1 = 8
    ap-northeast-2 = 9
    ap-northeast-3 = 10
    ap-southeast-1 = 11
    ap-southeast-2 = 12
    ca-central-1   = 13
    eu-central-1   = 14
    eu-north-1     = 15
    eu-west-1      = 16
    eu-west-2      = 17
    eu-west-3      = 18
    eu-south-1     = 19
    me-south-1     = 20
    sa-east-1      = 21
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}
