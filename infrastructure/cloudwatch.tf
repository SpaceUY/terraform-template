resource "aws_cloudwatch_log_group" "backend_logs" {
  name = "/ecs/${local.name_prefix}--backend"
  retention_in_days = 30
}
