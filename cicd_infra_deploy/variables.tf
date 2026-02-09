variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "github_repo_url" {
  description = "GitHub repository URL for Terraform code"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch to use"
  type        = string
  default     = "main"
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

variable "approval_sns_topic_arn" {
  description = "SNS topic ARN for manual approval notifications"
  type        = string
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
}
