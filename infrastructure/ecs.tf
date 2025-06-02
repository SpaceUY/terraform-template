resource "aws_ecr_repository" "ecr_repository" {
  name = "${replace(local.name_prefix, "--", "-")}-ecr-repository"
}

resource "aws_ecs_cluster" "cluster" {
  name = "${local.name_prefix}--ecs-cluster"
}

resource "aws_ecs_task_definition" "task_definition" {
  family = "${local.name_prefix}--task-definition"

  container_definitions = jsonencode([
    {
      name : "${local.name_prefix}--task-definition",
      image : aws_ecr_repository.ecr_repository.repository_url,
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
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${local.name_prefix}--ecs-task-exec-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "secrets_manager_access" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:*"]
    resources = [aws_secretsmanager_secret.secrets_manager.arn]
  }
}

resource "aws_iam_policy" "secrets_manager_access_policy" {
  name        = "${local.name_prefix}--secrets-manager-access-policy"
  description = "Gives the role assumed by ECS access to the appropriate secrets manager"
  policy      = data.aws_iam_policy_document.secrets_manager_access.json
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "secrets_manager_access_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.secrets_manager_access_policy.arn
}

resource "aws_ecs_service" "ecs_service" {
  name            = "${local.name_prefix}--ecs-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  launch_type     = "FARGATE"

  desired_count                      = 1
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_target_group.arn
    container_name   = "${local.name_prefix}--task-definition"
    container_port   = var.container_port
  }

  network_configuration {
    subnets          = slice(module.vpc.public_subnets, 0, 3)
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_sg.id]
  }

  lifecycle {
    ignore_changes = [
      task_definition
    ]
  }
}

resource "aws_security_group" "ecs_sg" {
  vpc_id = module.vpc.vpc_id
  name   = "${local.name_prefix}--ecs-sg"

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
