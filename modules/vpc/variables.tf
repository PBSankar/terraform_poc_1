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

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets. If not provided, will be calculated automatically"
  type        = list(string)
  default     = []
  
  validation {
    condition     = length(var.public_subnet_cidrs) == 0 || length(var.public_subnet_cidrs) == var.public_subnet_count
    error_message = "The number of public subnet CIDRs must match public_subnet_count or be empty for auto-calculation."
  }
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets. If not provided, will be calculated automatically"
  type        = list(string)
  default     = []
  
  validation {
    condition     = length(var.private_subnet_cidrs) == 0 || length(var.private_subnet_cidrs) == var.private_subnet_count
    error_message = "The number of private subnet CIDRs must match private_subnet_count or be empty for auto-calculation."
  }
}