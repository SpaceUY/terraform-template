output "distribution_id" {
  value = var.create ? aws_cloudfront_distribution.distribution[0].id : null
}

output "bucket_id" {
  value = var.create ? aws_s3_bucket.s3[0].id : null
}