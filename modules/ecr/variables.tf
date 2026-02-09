variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "repository_name" {
  description = "ECR Repository name"
  type        = string
  default     = ""
}

variable "image_version" {
  description = "Image version tag (e.g., 1.0, 1.02). If not provided, will auto-increment from latest version"
  type        = string
  default     = ""
}

variable "source_image" {
  description = "Source Docker image to push to ECR"
  type        = string
  default     = "nginx:latest"
}