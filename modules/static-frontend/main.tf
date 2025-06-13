data "aws_iam_policy_document" "s3_bucket_policy" {
  count = var.create ? 1 : 0
  
  statement {
    sid = "1"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${var.prefix}--s3/*",
    ]

    principals {
      type = "AWS"

      identifiers = [
        aws_cloudfront_origin_access_identity.origin_access_identity[0].iam_arn,
      ]
    }
  }
}

resource "aws_s3_bucket" "s3" {
  count  = var.create ? 1 : 0
  bucket = "${var.prefix}--s3"
}

resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  count  = var.create ? 1 : 0
  bucket = aws_s3_bucket.s3[0].id
  policy = data.aws_iam_policy_document.s3_bucket_policy[0].json
}

# Resource to avoid error "AccessControlListNotSupported: The bucket does not allow ACLs"
resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  count  = var.create ? 1 : 0
  bucket = aws_s3_bucket.s3[0].id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_acl" "acl" {
  # we need ownership controls to set ACLs
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]

  bucket = aws_s3_bucket.s3[0].id
  acl = "private"
}

resource "aws_cloudfront_distribution" "distribution" {
  count = var.create ? 1 : 0
  
  origin {
    domain_name = aws_s3_bucket.s3[0].bucket_regional_domain_name
    origin_id   = "${var.prefix}-cloudfront"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity[0].cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = [var.domain]

  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
    ]

    cached_methods = [
      "GET",
      "HEAD",
    ]

    target_origin_id = "${var.prefix}-cloudfront"

    viewer_protocol_policy     = "redirect-to-https"
    # CachingOptimized
    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    # SecurityHeadersPolicy
    response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03"
  }

  price_class = var.cloudfront_price_class

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = var.acm_arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1"
  }

  custom_error_response {
    error_code            = 400
    response_code         = 200
    error_caching_min_ttl = 0
    response_page_path    = "/index.html"
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    error_caching_min_ttl = 0
    response_page_path    = "/index.html"
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    error_caching_min_ttl = 0
    response_page_path    = "/index.html"
  }
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  count   = var.create ? 1 : 0
  comment = "access-identity-${var.prefix}--s3.s3.amazonaws.com"
}

data "aws_iam_policy_document" "deploy_policy_doc" {
  count = var.create ? 1 : 0
  statement {
    sid    = "S3Deploy"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      aws_s3_bucket.s3[0].arn,
      "${aws_s3_bucket.s3[0].arn}/*"
    ]
  }

  statement {
    sid    = "CloudFrontCacheInvalidation"
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation"
    ]
    resources = [
      aws_cloudfront_distribution.distribution[0].arn
    ]
  }
}

resource "aws_iam_user_policy" "deploy_policy" {
  count = var.create ? 1 : 0
  name   = "${var.prefix}--deploy-policy"
  user   = var.iam_deploying_user_name
  policy = data.aws_iam_policy_document.deploy_policy_doc[0].json
}