output "vpc_flow_logs_group_name" {
  value = aws_cloudwatch_log_group.vpc_flow_logs.name
}

output "application_logs_group_name" {
  value = aws_cloudwatch_log_group.application_logs.name
}

output "security_logs_group_name" {
  value = aws_cloudwatch_log_group.security_logs.name
}