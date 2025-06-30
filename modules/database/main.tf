module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.12.0"

  identifier = "${replace(var.prefix, "--", "-")}-rds"

  engine               = "postgres"
  engine_version       = "17.4"
  family               = "postgres17"
  major_engine_version = "17"
  instance_class       = var.db_size

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage

  db_name  = "${replace(var.prefix, "-", "_")}_db"
  username = "${replace(var.prefix, "-", "_")}_admin"
  manage_master_user_password = true

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.public_access ? [module.rds_sg.security_group_id, module.rds_public_sg.security_group_id] : [module.rds_sg.security_group_id]
  publicly_accessible = var.public_access

  maintenance_window              = "Sat:03:01-Sat:04:01"
  backup_window                   = "09:11-09:41"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60
  monitoring_role_name                  = "example-monitoring-role-name"
  monitoring_role_use_name_prefix       = true
  monitoring_role_description           = "Description for monitoring role"

  # Disable creation of option group - provide an option group or default AWS default
  create_db_option_group = false

  create_db_parameter_group = true
  parameters = [
    {
      name = "rds.force_ssl" 
      value = "0"
    }
  ]
}

module "rds_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.9.0"

  name        = "${var.prefix}--rds-sg"
  description = "RDS Security Group for VPC use"
  vpc_id      = var.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access within VPC"
      cidr_blocks = var.vpc_cidr_block
    }
  ]
}

module "rds_public_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.9.0"

  create = var.public_access

  name        = "${var.prefix}--rds-public-sg"
  description = "RDS Security Group for Public use (Only for unsecure mode)"
  vpc_id      = var.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL public access"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}
