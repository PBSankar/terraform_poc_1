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
    ManagedBy   = "Terraform"
    CostCenter  = "Engineering"
    Application = "PGE-Infrastructure"
    Compliance  = "Required"
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

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets. If not provided, will be calculated automatically"
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets. If not provided, will be calculated automatically"
  type        = list(string)
  default     = []
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "pge-infrastructure"
}

variable "environment" {
  description = "Environment name"
  type        = string


  default = "dev"
}

# variable "key_name" {
#   description = "EC2 Key Pair name (auto-generated)"
#   type        = string
#   default     = ""
# }

variable "container_image" {
  description = "Container image URI from GitHub"
  type        = string
  default     = ""
}

variable "ecr_image_version" {
  description = "ECR image version tag (e.g., 1.0, 1.02). If not provided, will auto-increment"
  type        = string
  default     = ""
}

variable "ecr_source_image" {
  description = "Source Docker image to push to ECR"
  type        = string
  default     = "nginx:latest"
}

# variable "ecr_repository_url" {
#   description = "ECR repository URL (e.g. 123456789.dkr.ecr.us-east-1.amazonaws.com/myapp)"
#   type        = string
#   default     = ""
# }

variable "repository_name" {
  description = "ECR Repository name"
  type        = string
  default     = "app-repository"
}

# variable "kms_key_arn" {
#   description = "KMS Key ARN for ECR encryption"
#   type        = string
#   default     = ""
# }

# variable "ecs_task_role_arn" {
#   description = "ECS Task Role ARN for KMS decryption"
#   type        = string
#   default     = ""
# }

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

variable "github_repo_url" {
  description = "GitHub repository URL for CodePipeline"
  type        = string
  default     = ""
  
}

variable "github_branch" {
  description = "GitHub repository branch for CodePipeline"
  type        = string
  default     = "main"
}

variable "github_token" {
  description = "GitHub personal access token for CodePipeline"
  type        = string
  sensitive   = true
}

variable "ecs_task_cpu" {
  description = "CPU units for ECS task"
  type        = number
  default     = 256
}

variable "ecs_task_memory" {
  description = "Memory for ECS task in MiB"
  type        = number
  default     = 512
}

variable "ecs_container_name" {
  description = "Name of the ECS container"
  type        = string
  default     = "app"
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "ecs_min_capacity" {
  description = "Minimum number of ECS tasks for autoscaling"
  type        = number
  default     = 1
}

variable "ecs_max_capacity" {
  description = "Maximum number of ECS tasks for autoscaling"
  type        = number
  default     = 4
}

# variable "cluster_name" {
#   description = "Name of the ECS cluster"
#   type        = string
#   default     = ""
# }

# variable "service_name" {
#   description = "Name of the ECS service"
#   type        = string
#   default     = ""
# }

variable "waf_rate_limit" {
  description = "WAF rate limit for requests per 5 minutes"
  type        = number
  default     = 2000
}

variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 1000
}

variable "daily_cost_threshold" {
  description = "Daily cost threshold for CloudWatch alarm"
  type        = number
  default     = 50
}