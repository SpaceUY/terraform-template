output "ecs_service_name" {
  value = aws_ecs_service.ecs_service.name
}

output "ecs_service_arn" {
  value = aws_ecs_service.ecs_service.arn
}

output "ecr_repository_name" {
  value = aws_ecr_repository.ecr_repository.name
}

output "ecr_repository_arn" {
  value = aws_ecr_repository.ecr_repository.arn
}

output "ecs_task_execution_role_name" {
  value = aws_iam_role.ecs_task_execution_role.name
}

output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}