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