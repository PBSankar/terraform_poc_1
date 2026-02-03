variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "public_subnet_count" {
  default     = 2
  description = "Number of public subnets to create"
  type        = number
}

variable "private_subnet_count" {
  default     = 2
  description = "Number of private subnets to create"
  type        = number
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}