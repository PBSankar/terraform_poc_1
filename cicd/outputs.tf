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