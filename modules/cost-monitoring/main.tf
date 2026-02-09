resource "aws_budgets_budget" "monthly_cost" {
  name              = "${var.project_name}-${var.environment}-monthly-budget"
  budget_type       = "COST"
  limit_amount      = var.monthly_budget_limit
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  cost_filter {
    name = "TagKeyValue"
    values = [
      "user:Project$${var.project_name}",
      "user:Environment$${var.environment}"
    ]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_alert_emails
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_alert_emails
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 90
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.budget_alert_emails
  }
}

resource "aws_ce_anomaly_monitor" "service_monitor" {
  name              = "${var.project_name}-${var.environment}-anomaly-monitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"

  tags = var.tags
}

resource "aws_ce_anomaly_subscription" "anomaly_subscription" {
  name      = "${var.project_name}-${var.environment}-anomaly-subscription"
  frequency = "DAILY"

  monitor_arn_list = [
    aws_ce_anomaly_monitor.service_monitor.arn
  ]

  subscriber {
    type    = "EMAIL"
    address = var.cost_anomaly_email
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      values        = ["100"]
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "estimated_charges" {
  alarm_name          = "${var.project_name}-${var.environment}-estimated-charges"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 21600
  statistic           = "Maximum"
  threshold           = var.daily_cost_threshold
  alarm_description   = "Alert when estimated charges exceed threshold"
  alarm_actions       = var.alarm_actions

  dimensions = {
    Currency = "USD"
  }

  tags = var.tags
}
