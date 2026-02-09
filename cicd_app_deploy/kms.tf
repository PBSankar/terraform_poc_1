# resource "aws_kms_key" "cicd_secrets" {
#   description             = "KMS key for CI/CD secrets encryption"
#   deletion_window_in_days = 7
#   enable_key_rotation     = true

#   tags = merge(var.common_tags, {
#     Name = "${var.project_name}-${var.environment}-cicd-secrets-key"
#   })
# }

# resource "aws_kms_alias" "cicd_secrets" {
#   name          = "alias/${var.project_name}-${var.environment}-cicd-secrets"
#   target_key_id = aws_kms_key.cicd_secrets.key_id
# }
