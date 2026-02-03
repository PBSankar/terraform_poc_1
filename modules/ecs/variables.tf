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

variable "container_image" {
  description = "Container image URI"
  type        = string
  default     = "ghcr.io/your-username/your-app:latest"
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "ecr_repository_url" {
  description = "ECR repository URL (e.g. 123456789.dkr.ecr.us-east-1.amazonaws.com/myapp)"
  type        = string
}

variable "image" {
  description = "Docker image tag to deploy. Use 'nginx:latest' for fallback"
  type        = string
  default     = "latest"
}


variable "execution_role_arn" {
  description = "ECS Task Execution Role ARN"
  type        = string
}


# Optional HTTPS (443). If empty, only HTTP(80) will be enabled.
variable "acm_certificate_arn" {
  description = "ACM certificate ARN for enabling HTTPS (443). Leave empty to enable only HTTP (80)."
  type        = string
  default     = ""
}
