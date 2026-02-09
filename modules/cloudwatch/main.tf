resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flowlogs/${var.project_name}"
  retention_in_days = 14
  kms_key_id        = var.kms_key_arn

  tags = merge(var.tags, {
    Name        = "${var.project_name}-vpc-flow-logs"
    Environment = var.environment
  })
}

resource "aws_cloudwatch_log_group" "application_logs" {
  name              = "/aws/application/${var.project_name}"
  retention_in_days = 30
  kms_key_id        = var.kms_key_arn

  tags = merge(var.tags, {
    Name        = "${var.project_name}-application-logs"
    Environment = var.environment
  })
}

resource "aws_cloudwatch_log_group" "security_logs" {
  name              = "/aws/security/${var.project_name}"
  retention_in_days = 90
  kms_key_id        = var.kms_key_arn

  tags = merge(var.tags, {
    Name        = "${var.project_name}-security-logs"
    Environment = var.environment
  })
}

resource "aws_cloudwatch_log_group" "rds_logs" {
  name              = "/aws/rds/${var.project_name}"
  retention_in_days = 30
  kms_key_id        = var.kms_key_arn

  tags = merge(var.tags, {
    Name        = "${var.project_name}-rds-logs"
    Environment = var.environment
  })
}

resource "aws_iam_role" "flow_logs" {
  name = "${var.project_name}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.project_name}-flow-logs-role"
    Environment = var.environment
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "${var.project_name}-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        # Resource = "*"
        Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
      }
    ]
  })
}

resource "aws_flow_log" "vpc" {
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = var.vpc_id

  log_format = "$${version} $${vpc-id} $${subnet-id} $${instance-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${action} $${log-status}"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-vpc-flow-logs"
    Environment = var.environment
  })
}

# S3 Bucket for VPC Flow Logs
resource "aws_s3_bucket" "vpc_flow_logs" {
  bucket = "${var.project_name}-${var.environment}-vpc-flow-logs-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-vpc-flow-logs"
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_public_access_block" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

data "aws_caller_identity" "current" {}

# VPC Flow Log to S3
resource "aws_flow_log" "vpc_to_s3" {
  log_destination      = aws_s3_bucket.vpc_flow_logs.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = var.vpc_id

  log_format = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status}"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-vpc-flow-logs-s3"
    Environment = var.environment
  })
}

resource "aws_cloudwatch_metric_alarm" "high_network_traffic" {
  alarm_name          = "${var.project_name}-high-network-traffic"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "1000000000"
  alarm_description   = "This metric monitors high network traffic"
  alarm_actions       = []

  tags = merge(var.tags, {
    Name        = "${var.project_name}-high-network-traffic-alarm"
    Environment = var.environment
  })
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project_name}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "ALB 5xx errors are high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.alarm_actions

  tags = merge(var.tags, {
    Name        = "${var.project_name}-alb-5xx-alarm"
    Environment = var.environment
  })
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.project_name}-ecs-cpu-high"
  alarm_description   = "ECS cluster CPU utilization is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    ClusterName = var.ecs_cluster_name
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.alarm_actions

  treat_missing_data = "notBreaching"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-ecs-cpu-alarm"
    Environment = var.environment
  })
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "${var.project_name}-ecs-memory-high"
  alarm_description   = "ECS cluster memory utilization is high"

  namespace           = "AWS/ECS"
  metric_name        = "MemoryUtilization"
  statistic          = "Average"
  period             = 300
  evaluation_periods = 2
  threshold          = 80
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ClusterName = var.ecs_cluster_name
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.alarm_actions

  treat_missing_data = "notBreaching"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-ecs-memory-alarm"
    Environment = var.environment
  })
}

resource "aws_cloudwatch_metric_alarm" "rds_connections_high" {
  alarm_name          = "${var.project_name}-rds-connections-high"
  alarm_description   = "RDS database connections are high"

  namespace           = "AWS/RDS"
  metric_name        = "DatabaseConnections"
  statistic          = "Average"
  period             = 300
  evaluation_periods = 2
  threshold          = 90
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBClusterIdentifier = var.rds_cluster_identifier
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.alarm_actions

  treat_missing_data = "notBreaching"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-rds-connections-alarm"
    Environment = var.environment
  })
}

resource "aws_cloudwatch_metric_alarm" "waf_blocked_requests" {
  alarm_name          = "${var.project_name}-waf-blocked-requests"
  alarm_description   = "High number of blocked requests by WAF"

  namespace           = "AWS/WAFV2"
  metric_name        = "BlockedRequests"
  statistic          = "Sum"
  period             = 300
  evaluation_periods = 2
  threshold          = 100
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    Rule   = "ALL"
    WebACL = var.waf_web_acl_name
    Region = var.region
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.alarm_actions

  treat_missing_data = "notBreaching"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-waf-blocked-alarm"
    Environment = var.environment
  })
}


resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn"],
            [".", "NetworkOut"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "Network Traffic"
          period  = 300
        }
      }
    ]
  })
}