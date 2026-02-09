output "vpc_flow_logs_group_name" {
  value = aws_cloudwatch_log_group.vpc_flow_logs.name
}

output "application_logs_group_name" {
  value = aws_cloudwatch_log_group.application_logs.name
}

output "security_logs_group_name" {
  value = aws_cloudwatch_log_group.security_logs.name
}

output "rds_logs_group_name" {
  value = aws_cloudwatch_log_group.rds_logs.name
}

output "vpc_flow_logs_s3_bucket" {
  description = "S3 bucket for VPC Flow Logs"
  value       = aws_s3_bucket.vpc_flow_logs.bucket
}

output "vpc_flow_logs_s3_arn" {
  description = "ARN of S3 bucket for VPC Flow Logs"
  value       = aws_s3_bucket.vpc_flow_logs.arn
}