output "budget_name" {
  description = "Name of the AWS Budget"
  value       = aws_budgets_budget.monthly_cost.name
}

output "anomaly_monitor_arn" {
  description = "ARN of the Cost Anomaly Monitor"
  value       = aws_ce_anomaly_monitor.service_monitor.arn
}

output "anomaly_subscription_arn" {
  description = "ARN of the Cost Anomaly Subscription"
  value       = aws_ce_anomaly_subscription.anomaly_subscription.arn
}
