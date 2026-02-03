variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of the security group"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key"
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

variable "database_name" {
  description = "Name of the database"
  type        = string
  default     = "maindb"
}

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

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "db_username" {
  description = "RDS database master username"
  type        = string
  default     = "adminuser"
}