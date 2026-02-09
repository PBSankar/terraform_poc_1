output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = aws_codebuild_project.docker_build.name
}

output "codepipeline_name" {
  description = "Name of the CodePipeline"
  value       = aws_codepipeline.ecs_pipeline.name
}

output "s3_artifacts_bucket" {
  description = "S3 bucket for CodePipeline artifacts"
  value       = aws_s3_bucket.codepipeline_artifacts.bucket
}

output "github_token_secret_arn" {
  description = "ARN of the GitHub token secret"
  value       = aws_secretsmanager_secret.github_token.arn
  sensitive   = true
}

output "cicd_kms_key_arn" {
  description = "ARN of the CI/CD KMS key"
  # value       = aws_kms_key.cicd_secrets.arn
  value       = var.kms_key_arn
}

# output "cicd_kms_key_id" {
#   description = "ID of the CI/CD KMS key"
#   value       = aws_kms_key.cicd_secrets.key_id
# }