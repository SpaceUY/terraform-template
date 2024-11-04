resource "aws_secretsmanager_secret" "secrets_manager" {
  name = "${local.name_prefix}--secrets-manager"
}

resource "aws_secretsmanager_secret_version" "secrets" {
  secret_id = aws_secretsmanager_secret.secrets_manager.id
  secret_string = jsonencode({
    PORT : var.container_port,
    DB_HOST : module.rds.db_instance_address,
    DB_USERNAME : module.rds.db_instance_username,
    # DB_PASSWORD : module.rds.db_instance_password,
    DB_DATABASE : "${var.project}_${terraform.workspace}",
    DB_PORT : module.rds.db_instance_port,
    SENDGRID_API_KEY: "SG.a"
  })

  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}