// ECR Repository
resource "aws_ecr_repository" "ecr_repository" {
  count = var.create ? 1 : 0
  name = "${replace(var.prefix, "--", "-")}-ecr-repository"
}



// Secrets Manager
resource "aws_secretsmanager_secret" "secrets_manager" {
  count = var.create ? 1 : 0
  name = "${var.prefix}--secrets-manager"
}

resource "aws_secretsmanager_secret_version" "secrets" {
  count = var.create ? 1 : 0
  secret_id = aws_secretsmanager_secret.secrets_manager[0].id
  secret_string = jsonencode(var.secrets)
}



// IAM Role
data "aws_iam_policy_document" "assume_role_policy" {
  count = var.create ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "secrets_manager_access" {
  count = var.create ? 1 : 0
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:*"]
    resources = [aws_secretsmanager_secret.secrets_manager[0].arn]
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  count = var.create ? 1 : 0
  name               = "${var.prefix}--ecs-task-exec-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy[0].json
}

resource "aws_iam_policy" "secrets_manager_access_policy" {
  count = var.create ? 1 : 0
  name        = "${var.prefix}--secrets-manager-access-policy"
  description = "Gives the role assumed by ECS access to the appropriate secrets manager"
  policy      = data.aws_iam_policy_document.secrets_manager_access[0].json
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  count = var.create ? 1 : 0
  role       = aws_iam_role.ecs_task_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "secrets_manager_access_policy" {
  count = var.create ? 1 : 0
  role       = aws_iam_role.ecs_task_execution_role[0].name
  policy_arn = aws_iam_policy.secrets_manager_access_policy[0].arn
}

// ALB
module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.9.0"

  create = var.create
  name        = "${var.prefix}--alb-sg"
  description = "ALB Security Group for HTTP Access"
  vpc_id      = module.vpc.vpc_id

  ingress_rules            = ["https-443-tcp", "http-80-tcp"]
  ingress_cidr_blocks      = ["0.0.0.0/0"]
  ingress_ipv6_cidr_blocks = ["::/0"]

  egress_with_cidr_blocks = [{
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr_block
  }]
}

resource "aws_alb" "alb" {
  count = var.create ? 1 : 0
  name               = "${var.prefix}--alb"
  load_balancer_type = "application"
  subnets            = var.vpc_public_subnets
  security_groups    = [module.alb_sg.security_group_id]
}

resource "aws_lb_target_group" "alb_target_group" {
  count = var.create ? 1 : 0
  name        = "${var.prefix}--alb-tg"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    matcher = "200,301,302"
    path    = "/"
    interval = 60
    unhealthy_threshold = 5
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "alb_listener" {
  count = var.create ? 1 : 0
  load_balancer_arn = aws_alb.alb[0].arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "alb_listener_ssl" {
  count = var.create ? 1 : 0
  load_balancer_arn = aws_alb.alb[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group[0].arn
  }
}



// ECS Cluster
resource "aws_ecs_cluster" "cluster" {
  count = var.create ? 1 : 0
  name = "${var.prefix}--ecs-cluster"
}

resource "aws_ecs_task_definition" "task_definition" {
  count = var.create ? 1 : 0
  family = "${var.prefix}--task-definition"

  container_definitions = jsonencode([
    {
      name : "${var.prefix}--task-definition",
      image : aws_ecr_repository.ecr_repository[0].repository_url,
      essential : true,
      portMappings : var.task_port_mappings,
      cpu : var.task_cpu,
      memory : var.task_memory
    }
  ])

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role[0].arn
}

resource "aws_security_group" "ecs_sg" {
  count = var.create ? 1 : 0
  vpc_id = var.vpc_id
  name   = "${var.prefix}--ecs-sg"

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # Only allowing traffic in from the load balancer security group
    security_groups = [module.alb_sg.security_group_id]
  }

  egress {
    from_port   = 0             # Allowing any incoming port
    to_port     = 0             # Allowing any outgoing port
    protocol    = "-1"          # Allowing any outgoing protocol 
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}

resource "aws_ecs_service" "ecs_service" {
  count = var.create ? 1 : 0
  name            = "${var.prefix}--ecs-service"
  cluster         = aws_ecs_cluster.cluster[0].id
  task_definition = aws_ecs_task_definition.task_definition[0].arn
  launch_type     = "FARGATE"

  desired_count                      = 1
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  
  load_balancer {
    target_group_arn = aws_lb_target_group.alb_target_group[0].arn
    container_name   = "${var.prefix}--task-definition"
    container_port   = var.container_port
  }

  network_configuration {
    subnets          = var.vpc_public_subnets
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_sg[0].id]
  }

  lifecycle {
    ignore_changes = [
      task_definition
    ]
  }
}



// Cloudwatch Log Group
resource "aws_cloudwatch_log_group" "backend_logs" {
  count = var.create ? 1 : 0
  name = "/ecs/${var.prefix}--backend"
  retention_in_days = 30
}



// IAM Permissions
data "aws_iam_policy_document" "deploy_policy_doc" {
  count = var.create ? 1 : 0
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
    resources = [aws_ecr_repository.ecr_repository[0].arn]
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
    resources = [aws_ecs_service.ecs_service[0].id]
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
    resources = [aws_iam_role.ecs_task_execution_role[0].arn]
  }
}

resource "aws_iam_user_policy" "deploy_policy" {
  count = var.create ? 1 : 0
  name   = "${var.prefix}--deploy-policy"
  user   = var.iam_deploying_user_name
  policy = data.aws_iam_policy_document.deploy_policy_doc[0].json
}