# S3 Bucket for Terraform Pipeline artifacts
resource "aws_s3_bucket" "terraform_pipeline_artifacts" {
  bucket = "terraform-pipeline-artifacts-${random_string.pipeline_suffix.result}"
}

resource "aws_s3_bucket_versioning" "terraform_pipeline_artifacts_versioning" {
  bucket = aws_s3_bucket.terraform_pipeline_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_pipeline_artifacts_encryption" {
  bucket = aws_s3_bucket.terraform_pipeline_artifacts.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "random_string" "pipeline_suffix" {
  length  = 8
  special = false
  upper   = false
}

# IAM Role for Terraform CodePipeline
resource "aws_iam_role" "terraform_pipeline_role" {
  name = "terraform-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Terraform CodePipeline
resource "aws_iam_role_policy" "terraform_pipeline_policy" {
  role = aws_iam_role.terraform_pipeline_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketVersioning",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.terraform_pipeline_artifacts.arn,
          "${aws_s3_bucket.terraform_pipeline_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = "*"
      }
    ]
  })
}

# CodeBuild Projects (assuming they already exist)
# You'll need to replace these with your actual CodeBuild project names
variable "terraform_plan_project_name" {
  description = "Name of the Terraform Plan CodeBuild project"
  type        = string
  default     = "terraform-plan-project"
}

variable "terraform_apply_project_name" {
  description = "Name of the Terraform Apply CodeBuild project"
  type        = string
  default     = "terraform-apply-project"
}

variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = "your-github-username"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "your-repo-name"
}

variable "github_branch" {
  description = "GitHub branch to monitor"
  type        = string
  default     = "main"
}

# Terraform CodePipeline
resource "aws_codepipeline" "terraform_pipeline" {
  name     = "terraform-infrastructure-pipeline"
  role_arn = aws_iam_role.terraform_pipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.terraform_pipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = var.github_owner
        Repo       = var.github_repo
        Branch     = var.github_branch
        OAuthToken = var.github_token
      }
    }
  }

  stage {
    name = "Plan"

    action {
      name             = "TerraformPlan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["plan_output"]
      version          = "1"

      configuration = {
        ProjectName = var.terraform_plan_project_name
      }
    }
  }

  stage {
    name = "ManualApproval"

    action {
      name     = "ApprovalForApply"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        CustomData = "Please review the Terraform plan and approve to proceed with apply"
      }
    }
  }

  stage {
    name = "Apply"

    action {
      name            = "TerraformApply"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["plan_output"]
      version         = "1"

      configuration = {
        ProjectName = var.terraform_apply_project_name
      }
    }
  }
}

# Outputs
output "terraform_pipeline_name" {
  description = "Name of the Terraform CodePipeline"
  value       = aws_codepipeline.terraform_pipeline.name
}

output "terraform_pipeline_arn" {
  description = "ARN of the Terraform CodePipeline"
  value       = aws_codepipeline.terraform_pipeline.arn
}

output "artifacts_bucket_name" {
  description = "Name of the S3 bucket for pipeline artifacts"
  value       = aws_s3_bucket.terraform_pipeline_artifacts.bucket
}