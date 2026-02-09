resource "aws_codebuild_project" "terraform_plan" {
  name          = "${var.project_name}-${var.environment}-plan"
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:latest"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOT
      version: 0.2
      phases:
        install:
          commands:
            - terraform --version
        pre_build:
          commands:
            - terraform init
        build:
          commands:
            - terraform plan -out=tfplan
      artifacts:
        files:
          - */**/*
          - tfplan
    EOT
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-plan"
  })
}

resource "aws_codebuild_project" "terraform_apply" {
  name          = "${var.project_name}-${var.environment}-apply"
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:latest"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOT
      version: 0.2
      phases:
        install:
          commands:
            - terraform --version
        pre_build:
          commands:
            - terraform init
        build:
          commands:
            - terraform apply -auto-approve
    EOT
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-apply"
  })
}
