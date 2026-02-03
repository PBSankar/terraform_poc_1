# outputs.tf
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.ecs.alb_dns_name
}

output "alb_url" {
  description = "URL of the Application Load Balancer"
  value       = "http://${module.ecs.alb_dns_name}"
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "rds_cluster_endpoint" {
  description = "RDS cluster endpoint"
  value       = module.rds.cluster_endpoint
}

output "rds_cluster_reader_endpoint" {
  description = "RDS cluster reader endpoint"
  value       = module.rds.cluster_reader_endpoint
}

output "db_username_secret_arn" {
  description = "ARN of the DB username secret in KMS"
  value       = module.rds.db_username_secret_arn
}

output "db_password_secret_arn" {
  description = "ARN of the DB password secret in KMS"
  value       = module.rds.db_password_secret_arn
}

output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = module.cicd.codebuild_project_name
}

output "codepipeline_name" {
  description = "Name of the CodePipeline"
  value       = module.cicd.codepipeline_name
}