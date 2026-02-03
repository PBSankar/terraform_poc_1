variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "pge"
    Owner       = "trianz"
    c-modernize = "true"
  }
}

variable "public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
  default     = 1
}

variable "private_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
  default     = 2
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "pge-infrastructure"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "key_name" {
  description = "EC2 Key Pair name (auto-generated)"
  type        = string
  default     = ""
}

variable "container_image" {
  description = "Container image URI from GitHub"
  type        = string
  default     = ""
}

# variable "ecr_repository_url" {
#   description = "ECR repository URL (e.g. 123456789.dkr.ecr.us-east-1.amazonaws.com/myapp)"
#   type        = string
#   default     = ""
# }

variable "repository_name" {
  description = "ECR Repository name"
  type        = string
  default     = ""
}

variable "kms_key_arn" {
  description = "KMS Key ARN for ECR encryption"
  type        = string
  default     = ""
}

variable "ecs_task_role_arn" {
  description = "ECS Task Role ARN for KMS decryption"
  type        = string
  default     = ""
}

variable "alert_email_address" {
  description = "Email address for SNS alerts"
  type        = string
}
# variable "slack_webhook_url" {
#   description = "Slack Webhook URL for SNS alerts"
#   type        = string
# }

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.medium"
}

variable "instance_count" {
  description = "Number of RDS instances"
  type        = number
  default     = 2
}

variable "db_username" {
  description = "RDS database master username"
  type        = string
  default     = "adminuser"
}

variable "github_token" {
  description = "GitHub personal access token for CodePipeline"
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = ""
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = ""
}