variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "region" {
  description = "AWS region"
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

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB"
  type        = string
  
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "rds_cluster_identifier" {
  description = "RDS/Aurora cluster identifier"
  type        = string
}

variable "alarm_actions" {
  description = "List of SNS topic ARNs for alarm notifications"
  type        = list(string)
  default     = []
}