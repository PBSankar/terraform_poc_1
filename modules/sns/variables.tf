
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

variable "alert_email_address" {
  description = "Email address for SNS alerts"
  type        = string
}

variable "" {
  
}
# variable "slack_webhook_url" {
#   description = "Slack Webhook URL for SNS alerts"
#   type        = string
# }