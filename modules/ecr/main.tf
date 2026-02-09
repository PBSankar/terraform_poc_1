############################
# ECR Repository
############################
resource "aws_ecr_repository" "main" {
  name                 = "${var.project_name}-${var.environment}-${var.repository_name}"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  # Error handling: Prevent accidental deletion of repository with images
  lifecycle {
    prevent_destroy = false
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-${var.repository_name}"
    Environment = var.environment
    Project     = var.project_name
    Module      = "ecr"
  })
}