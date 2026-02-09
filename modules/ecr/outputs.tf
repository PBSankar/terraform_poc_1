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

output "image_version" {
  description = "Current image version pushed to ECR"
  value       = local.image_version
}

output "image_uri_versioned" {
  description = "ECR image URI with version tag"
  value       = "${aws_ecr_repository.main.repository_url}:${local.image_version}"
}

output "image_uri_latest" {
  description = "ECR image URI with latest tag"
  value       = "${aws_ecr_repository.main.repository_url}:latest"
}
