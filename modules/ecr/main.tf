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

####### iam.tf
data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "${var.project_name}-${var.environment}-ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
  
  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-ecs-task-execution-role"
    Project     = var.project_name
    Environment = var.environment
    Module      = "ecr"
  })
}

# Attach AWS managed policies that include ECR pull + CW logs
resource "aws_iam_role_policy_attachment" "ecs_exec_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional policy for CloudWatch Logs
resource "aws_iam_role_policy_attachment" "ecs_cloudwatch_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}