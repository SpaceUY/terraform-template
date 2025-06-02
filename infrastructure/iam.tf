resource "aws_iam_user" "backend_user" {
  name = "${local.name_prefix}--backend-user-iam"
}

resource "aws_iam_role" "backend_role" {
  name = "${local.name_prefix}--backend-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "backend_policy" {
  name = "${local.name_prefix}--backend-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "autoscaling:Describe*",
          "cloudwatch:*",
          "logs:*",
          "sns:*",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:GetRole"
        ],
        "Effect" : "Allow",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "iam:CreateServiceLinkedRole",
        "Resource" : "arn:aws:iam::*:role/aws-service-role/events.amazonaws.com/AWSServiceRoleForCloudWatchEvents*",
        "Condition" : {
          "StringLike" : {
            "iam:AWSServiceName" : "events.amazonaws.com"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:*"
        ],
        "Resource" : aws_secretsmanager_secret.secrets_manager.arn
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "backend_user_policy_attachment" {
  user       = aws_iam_user.backend_user.name
  policy_arn = aws_iam_policy.backend_policy.arn
}

resource "aws_iam_role_policy_attachment" "backend_role_policy_attachment" {
  role       = aws_iam_role.backend_role.name
  policy_arn = aws_iam_policy.backend_policy.arn
}

resource "aws_iam_access_key" "backend_user_creds" {
  user = aws_iam_user.backend_user.name
}

resource "aws_iam_user" "bitbucket_deploy_user" {
  name = "${local.name_prefix}--bitbucket-deploy-user"
}

data "aws_iam_policy_document" "bitbucket_frontend_deploy_policy_doc" {
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
      aws_s3_bucket.frontend_s3.arn,
      "${aws_s3_bucket.frontend_s3.arn}/*"
    ]
  }

  statement {
    sid    = "CloudFrontCacheInvalidation"
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation"
    ]
    resources = [
      aws_cloudfront_distribution.frontend_distribution.arn
    ]
  }
}

resource "aws_iam_user_policy" "bitbucket_frontend_deploy_policy" {
  name   = "${local.name_prefix}--bitbucket-frontend-deploy-policy"
  user   = aws_iam_user.bitbucket_deploy_user.name
  policy = data.aws_iam_policy_document.bitbucket_frontend_deploy_policy_doc.json
}

data "aws_iam_policy_document" "bitbucket_backend_deploy_policy_doc" {
  statement {
    sid    = "ECR"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]
    resources = [aws_ecr_repository.ecr_repository.arn]
  }

  statement {
    sid    = "ECRGLOBAL"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ECS"
    effect = "Allow"
    actions = [
      "ecs:UpdateService"
    ]
    resources = [aws_ecs_service.ecs_service.id]
  }

  statement {
    sid    = "ECSGLOBAL"
    effect = "Allow"
    actions = [
      "ecs:RegisterTaskDefinition"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "PassRole"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [aws_iam_role.ecs_task_execution_role.arn]
  }
}

resource "aws_iam_user_policy" "bitbucket_backend_deploy_policy" {
  name   = "${local.name_prefix}--bitbucket-backend-deploy-policy"
  user   = aws_iam_user.bitbucket_deploy_user.name
  policy = data.aws_iam_policy_document.bitbucket_backend_deploy_policy_doc.json
}

resource "aws_iam_access_key" "bitbucket_user_creds" {
  user = aws_iam_user.bitbucket_deploy_user.name
}

resource "aws_iam_user" "cert_manager_user" {
  name = "${local.name_prefix}--cert-manager-user"
}

resource "aws_iam_access_key" "cert_manager_user_creds" {
  user = aws_iam_user.cert_manager_user.name
}

data "aws_iam_policy_document" "cert_manager_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "route53:GetChange"
    ]
    resources = ["arn:aws:route53:::change/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets"
    ]
    resources = ["arn:aws:route53:::hostedzone/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZonesByName"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cert_manager_policy" {
  name   = "${local.name_prefix}--cert-manager-policy"
  policy = data.aws_iam_policy_document.cert_manager_policy_doc.json
}

resource "aws_iam_user_policy_attachment" "cert_manager_user_policy_attachment" {
  user       = aws_iam_user.cert_manager_user.name
  policy_arn = aws_iam_policy.cert_manager_policy.arn
}

data "aws_iam_policy_document" "cluster_autoscaler_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:GetInstanceTypesFromInstanceRequirements",
      "eks:DescribeNodegroup"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cluster_autoscaler_policy" {
  name   = "${local.name_prefix}--cluster-autoscaler-policy"
  policy = data.aws_iam_policy_document.cluster_autoscaler_policy_doc.json
}
