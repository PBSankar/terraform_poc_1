resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-alerts"
    Environment = var.environment
  })
}

resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email_address
  confirmation_timeout_in_minutes = 5

}

# For Production, consider adding SMS or Lambda subscriptions for critical alerts.
# resource "aws_sns_topic_subscription" "slack" {
#   topic_arn = aws_sns_topic.alerts.arn
#   protocol  = "https"
#   endpoint  = var.slack_webhook_url
# }