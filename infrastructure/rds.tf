resource "random_password" "master" {
  length  = 20
  special = false
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.7.0"

  identifier = "${replace(local.name_prefix, "--", "-")}-rds"

  engine               = "postgres"
  engine_version       = "13.13"
  family               = "postgres13"
  major_engine_version = "13"
  instance_class       = var.db_size

  allocated_storage     = 20
  max_allocated_storage = 40

  db_name  = "${replace(var.project, "-", "_")}_${terraform.workspace}"
  username = "${replace(var.project, "-", "_")}_admin"
  manage_master_user_password = false
  password = try(var.existing_db_password, random_password.master.result)

  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = var.secured ? [module.rds_sg.security_group_id] : [module.rds_sg.security_group_id, module.rds_public_sg.security_group_id]
  publicly_accessible = !var.secured

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

  # Disable creation of parameter group - provide a parameter group or default to AWS default
  create_db_parameter_group = false
}

module "rds_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.9.0"

  name        = "${local.name_prefix}--rds-sg"
  description = "RDS Security Group for VPC use"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    }
  ]
}

module "rds_public_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.9.0"

  create = !var.secured

  name        = "${local.name_prefix}--rds-public-sg"
  description = "RDS Security Group for Public use (Only for unsecure mode)"
  vpc_id      = module.vpc.vpc_id

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
