variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 1000
}

variable "daily_cost_threshold" {
  description = "Daily cost threshold for CloudWatch alarm"
  type        = number
  default     = 50
}

variable "budget_alert_emails" {
  description = "List of email addresses for budget alerts"
  type        = list(string)
}

variable "cost_anomaly_email" {
  description = "Email address for cost anomaly alerts"
  type        = string
}

variable "alarm_actions" {
  description = "List of SNS topic ARNs for alarm notifications"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
