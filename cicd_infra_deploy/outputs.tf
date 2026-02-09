output "pipeline_name" {
  description = "Name of the infrastructure deployment pipeline"
  value       = aws_codepipeline.terraform_pipeline.name
}

output "pipeline_arn" {
  description = "ARN of the infrastructure deployment pipeline"
  value       = aws_codepipeline.terraform_pipeline.arn
}

output "artifacts_bucket" {
  description = "S3 bucket for pipeline artifacts"
  value       = aws_s3_bucket.pipeline_artifacts.bucket
}

output "plan_project_name" {
  description = "CodeBuild project name for Terraform plan"
  value       = aws_codebuild_project.terraform_plan.name
}

output "apply_project_name" {
  description = "CodeBuild project name for Terraform apply"
  value       = aws_codebuild_project.terraform_apply.name
}
