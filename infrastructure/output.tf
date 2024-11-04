output "bb_backend_deployment_variables" {
  sensitive = true
  value = tomap({
    PROJECT_NAME          = var.project
    WORKSPACE_NAME        = terraform.workspace
    AWS_ACCOUNT_ID        = data.aws_caller_identity.current.account_id
    SECRETS_MANAGER_ARN   = aws_secretsmanager_secret.secrets_manager.arn
    AWS_DEFAULT_REGION    = var.region
    AWS_ACCESS_KEY_ID     = aws_iam_access_key.bitbucket_user_creds.id
    AWS_SECRET_ACCESS_KEY = aws_iam_access_key.bitbucket_user_creds.secret
  })
}

output "bb_frontend_deployment_variables" {
  sensitive = true
  value = tomap({
    REACT_APP_BACK_URL    = "https://${var.backend_domain}"
    DISTRIBUTION_ID       = aws_cloudfront_distribution.frontend_distribution.id
    S3_BUCKET             = aws_s3_bucket.frontend_s3.id
    REACT_APP_ENV         = terraform.workspace
    AWS_DEFAULT_REGION    = var.region
    AWS_ACCESS_KEY_ID     = aws_iam_access_key.bitbucket_user_creds.id
    AWS_SECRET_ACCESS_KEY = aws_iam_access_key.bitbucket_user_creds.secret
  })
}

output "dns_records" {
  sensitive = false
  value = tomap({
    Frontend = ["CNAME", var.frontend_domain, aws_cloudfront_distribution.frontend_distribution.domain_name]
    Backend  = ["CNAME", var.backend_domain, aws_alb.alb.dns_name]
  })
}

output "region" {
  value = var.region
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "agones_sdk_role_arn" {
  value = aws_iam_role.agones_sdk_role.arn
}

output "cluster_autoscaler_role_arn" {
  value = aws_iam_role.cluster_autoscaler_role.arn
}

output "cert_manager_user" {
  sensitive = true
  value = tomap({
    AWS_ACCESS_KEY_ID     = aws_iam_access_key.cert_manager_user_creds.id
    AWS_SECRET_ACCESS_KEY = aws_iam_access_key.cert_manager_user_creds.secret
  })
}

output "cert_manager_user_key_id" {
  sensitive = true
  value = aws_iam_access_key.cert_manager_user_creds.id
}

output "cert_manager_user_secret_key" {
  sensitive = true
  value = aws_iam_access_key.cert_manager_user_creds.secret
}

output "db_host" {
  sensitive = true
  value = module.rds.db_instance_address
}

output "db_user" {
  sensitive = true
  value = module.rds.db_instance_username
}

output "db_password" {
  sensitive = true
  value = try(var.existing_db_password, random_password.master.result)
}

output "db_database" {
  sensitive = true
  value = "${var.project}_${terraform.workspace}"
}
