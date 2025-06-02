output "backend_deployment_variables" {
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

output "frontend_deployment_variables" {
  sensitive = true
  value = tomap({
    REACT_APP_BACK_URL    = "https://${var.backend_domain}"
    DISTRIBUTION_ID       = module.frontend.distribution_id
    S3_BUCKET             = module.frontend.s3_bucket_id
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
