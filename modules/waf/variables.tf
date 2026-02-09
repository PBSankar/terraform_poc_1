variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "alb_arn" {
  description = "ARN of the Application Load Balancer"
  type        = string
}

variable "rate_limit" {
  description = "Rate limit for requests per 5 minutes"
  type        = number
  default     = 2000
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
