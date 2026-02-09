# IAM Role for ECS Task Execution
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
    Module      = "ecs"
  })
}

# Attach AWS managed policies that include ECR pull + CW logs
resource "aws_iam_role_policy_attachment" "ecs_exec_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Custom policy for CloudWatch Logs (least privilege)
resource "aws_iam_role_policy" "ecs_cloudwatch_logs" {
  name = "${var.project_name}-${var.environment}-ecs-cloudwatch-logs"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:*:log-group:/ecs/${var.project_name}-${var.environment}-*:*"
      }
    ]
  })
}

# IAM Role for ECS Task (Application Permissions)
resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.project_name}-${var.environment}-ecsTaskRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
  
  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-ecs-task-role"
    Project     = var.project_name
    Environment = var.environment
    Module      = "ecs"
  })
}

# Task role policy for application permissions
resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "${var.project_name}-${var.environment}-ecs-task-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.region}:*:secret:${var.project_name}-${var.environment}-db-*"
        ]
      },
      {
        Sid    = "KMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = [
          "arn:aws:kms:${var.region}:*:key/*"
        ]
        Condition = {
          StringEquals = {
            "kms:ViaService" = [
              "secretsmanager.${var.region}.amazonaws.com",
              "s3.${var.region}.amazonaws.com"
            ]
          }
        }
      },
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::${var.project_name}-${var.environment}-*/*"
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:*:log-group:/ecs/${var.project_name}-${var.environment}-*:*"
      }
    ]
  })
}
