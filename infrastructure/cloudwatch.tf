resource "aws_cloudwatch_log_group" "backend_logs" {
  name = "/ecs/${local.name_prefix}--backend"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "backend_gs_logs" {
  name = "/ecs/${local.name_prefix_gs}--backend"
  retention_in_days = 30
}
