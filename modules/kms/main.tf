data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# KMS Key for RDS and ECS
resource "aws_kms_key" "main" {
  description             = "KMS key for RDS and ECS encryption"
  deletion_window_in_days = 7
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })
  
  tags = merge(var.tags, {
    Name = "main-kms-key"
  })
}

# KMS Key Alias
resource "aws_kms_alias" "main" {
  name          = "alias/pge-main-kms-key"
  target_key_id = aws_kms_key.main.key_id
}