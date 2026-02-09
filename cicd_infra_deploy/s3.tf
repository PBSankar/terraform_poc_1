resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "${var.project_name}-${var.environment}-infra-pipeline-artifacts-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-infra-pipeline-artifacts"
  })
}

resource "aws_s3_bucket_versioning" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_caller_identity" "current" {}
