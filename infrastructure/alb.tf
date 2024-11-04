resource "aws_alb" "alb" {
  name               = "${local.name_prefix}--alb"
  load_balancer_type = "application"
  subnets            = slice(module.vpc.public_subnets, 0, 3)
  security_groups    = [module.alb_sg.security_group_id]
}

module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.9.0"

  name        = "${local.name_prefix}--alb-sg"
  description = "ALB Security Group for HTTP Access"
  vpc_id      = module.vpc.vpc_id

  ingress_rules            = ["https-443-tcp", "http-80-tcp"]
  ingress_cidr_blocks      = ["0.0.0.0/0"]
  ingress_ipv6_cidr_blocks = ["::/0"]

  egress_with_cidr_blocks = [{
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = module.vpc.vpc_cidr_block
  }]
}

resource "aws_lb_target_group" "alb_target_group" {
  name        = "${local.name_prefix}--alb-tg"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id
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
  load_balancer_arn = aws_alb.alb.arn
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
  load_balancer_arn = aws_alb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.backend_acm_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}
