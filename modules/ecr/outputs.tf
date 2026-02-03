output "repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.main.repository_url
}

output "repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.main.name
}

output "repository_arn" {
  description = "ECR repository ARN"
  value       = aws_ecr_repository.main.arn
}

output "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = aws_iam_role.ecs_task_execution.arn
}
