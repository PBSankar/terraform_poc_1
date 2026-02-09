output "cluster_endpoint" {
  description = "RDS cluster endpoint"
  value       = aws_rds_cluster.main.endpoint
}

output "cluster_reader_endpoint" {
  description = "RDS cluster reader endpoint"
  value       = aws_rds_cluster.main.reader_endpoint
}

output "cluster_identifier" {
  description = "RDS cluster identifier"
  value       = aws_rds_cluster.main.cluster_identifier
}

output "cluster_arn" {
  description = "RDS cluster ARN"
  value       = aws_rds_cluster.main.arn
}

output "database_name" {
  description = "Database name"
  value       = aws_rds_cluster.main.database_name
}

output "port" {
  description = "Database port"
  value       = aws_rds_cluster.main.port
}

output "db_username_secret_arn" {
  description = "ARN of the DB username secret"
  value       = aws_secretsmanager_secret.db_username.arn
}

output "db_password_secret_arn" {
  description = "ARN of the DB password secret"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "rds_proxy_endpoint" {
  description = "RDS Proxy endpoint for connection pooling"
  value       = aws_db_proxy.main.endpoint
}

output "rds_proxy_arn" {
  description = "ARN of the RDS Proxy"
  value       = aws_db_proxy.main.arn
}