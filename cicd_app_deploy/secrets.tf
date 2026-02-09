# Store GitHub token in Secrets Manager
resource "aws_secretsmanager_secret" "github_token" {
  name        = "${var.project_name}-${var.environment}-github-token"
  description = "GitHub OAuth token for CodePipeline"
  # kms_key_id              = aws_kms_key.cicd_secrets.arn
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-github-token"
  })
}

resource "aws_secretsmanager_secret_version" "github_token" {
  secret_id     = aws_secretsmanager_secret.github_token.id
  secret_string = var.github_token
}

# Data source to retrieve the secret
data "aws_secretsmanager_secret_version" "github_token" {
  secret_id  = aws_secretsmanager_secret.github_token.id
  depends_on = [aws_secretsmanager_secret_version.github_token]
}
