variable "vpc_id" {
  description = "VPC ID"
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

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "route_table_ids" {
  description = "Route table IDs"
  type        = list(string)
}

variable "vpc_endpoint_security_group_id" {
  description = "VPC endpoint security group ID"
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