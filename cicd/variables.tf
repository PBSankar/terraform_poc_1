variable "project_name" {
  description = "Name of the project"
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

variable "repository_name" {
  description = "ECR Repository name"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
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