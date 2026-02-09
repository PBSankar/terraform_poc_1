variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  
}

variable "public_subnet_ids" {
  description = "Public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "web_security_group_id" {
  description = "Web security group ID"
  type        = string
}

variable "app_security_group_id" {
  description = "App security group ID"
  type        = string
}


variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# variable "container_image" {
#   description = "Container image URI"
#   type        = string
#   default     = "ghcr.io/your-username/your-app:latest"
# }

variable "region" {
  description = "AWS region"
  type        = string
}

# variable "ecr_repository_url" {
#   description = "ECR repository URL (e.g. 123456789.dkr.ecr.us-east-1.amazonaws.com/myapp)"
#   type        = string
# }

variable "image" {
  description = "Docker image tag to deploy. Use 'nginx:latest' for fallback"
  type        = string
  default     = "latest"
}


# Optional HTTPS (443). If empty, only HTTP(80) will be enabled.
variable "acm_certificate_arn" {
  description = "ACM certificate ARN for enabling HTTPS (443). Leave empty to enable only HTTP (80)."
  type        = string
  default     = ""
}

variable "task_cpu" {
  description = "CPU units for the task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory for the task in MiB (512, 1024, 2048, 4096, 8192)"
  type        = number
  default     = 512
}

variable "container_name" {
  description = "Name of the container"
  type        = string
  default     = "app"
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
}

variable "min_capacity" {
  description = "Minimum number of tasks for autoscaling"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks for autoscaling"
  type        = number
  default     = 4
}

variable "cpu_target_value" {
  description = "Target CPU utilization percentage for autoscaling"
  type        = number
  default     = 70
}

variable "memory_target_value" {
  description = "Target memory utilization percentage for autoscaling"
  type        = number
  default     = 80
}

variable "alb_request_count_target" {
  description = "Target ALB request count per target for autoscaling"
  type        = number
  default     = 1000
}

# variable "execution_role_arn" {
#   description = "ARN of the IAM role that ECS tasks will use for execution"
#   type        = string
# }