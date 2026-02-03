variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
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

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment  = "dev"
    Project      = "pge"
    Owner        = "trianz"
    c-modernize  = "true"
  }
}