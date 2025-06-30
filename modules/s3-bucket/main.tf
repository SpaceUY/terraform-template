locals {
  create_ecs_policy = var.create && var.ecs_task_execution_role_name != ""
}

module "s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.0.2"

  create_bucket = var.create

  bucket = "${var.prefix}--s3"
  acl    = var.acl
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  count = local.create_ecs_policy ? 1 : 0
  
  statement {
    effect = "Allow"
    actions = ["s3:*"]
    resources = ["arn:aws:s3:::${module.s3-bucket.s3_bucket_id}/*"]
  }
}

resource "aws_iam_policy" "s3_bucket_policy" {
  count = local.create_ecs_policy ? 1 : 0

  name = "${var.prefix}--s3-bucket-policy"
  description = "Gives the role assumed by ECS access to the appropriate S3 bucket"
  policy = data.aws_iam_policy_document.s3_bucket_policy[0].json
}

resource "aws_iam_role_policy_attachment" "s3_bucket_policy" {
  count = local.create_ecs_policy ? 1 : 0

  role = var.ecs_task_execution_role_name
  policy_arn = aws_iam_policy.s3_bucket_policy[0].arn
}

