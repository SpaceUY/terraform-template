variable "create" {
  type = bool
  default = true
  description = "Whether to create the database resources"
}

variable "prefix" {
  type = string
  description = "Prefix for the database resources"
}

variable "public_access" {
  type = bool
  default = false
  description = "Whether to allow public access to the database"
}

variable "db_size" {
  type = string
  default = "db.t3.small"
  description = "Size of the database"
}

variable "vpc_id" {
  type = string
  description = "VPC ID"
}

variable "vpc_cidr_block" {
  type = string
  description = "VPC CIDR block"
}

variable "db_subnet_group_name" {
  type = string
  description = "DB subnet group name"
}

variable "allocated_storage" {
  type = number
  default = 20
  description = "Allocated storage"
}

variable "max_allocated_storage" {
  type = number
  default = 40
  description = "Max allocated storage"
}


