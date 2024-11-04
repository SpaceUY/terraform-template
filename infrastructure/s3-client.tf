data "aws_iam_policy_document" "frontend_s3_bucket_policy" {
  statement {
    sid = "1"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${local.name_prefix}--frontend/*",
    ]

    principals {
      type = "AWS"

      identifiers = [
        aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn,
      ]
    }
  }
}

resource "aws_s3_bucket" "frontend_s3" {
  bucket = "${local.name_prefix}--frontend"
  //policy = data.aws_iam_policy_document.s3_bucket_policy.json
}

resource "aws_s3_bucket_policy" "frontend_s3_bucket_policy" {
  bucket = aws_s3_bucket.frontend_s3.id
  policy = data.aws_iam_policy_document.frontend_s3_bucket_policy.json
}

# Resource to avoid error "AccessControlListNotSupported: The bucket does not allow ACLs"
resource "aws_s3_bucket_ownership_controls" "frontend_s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.frontend_s3.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_acl" "acl" {
  # we need ownership controls to set ACLs
  depends_on = [aws_s3_bucket_ownership_controls.frontend_s3_bucket_acl_ownership]

  bucket = aws_s3_bucket.frontend_s3.id
  acl = "private"
}
