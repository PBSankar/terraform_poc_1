# Example terraform.tfvars file
# Copy this to terraform.tfvars and modify as needed

# AWS Configuration
region = "us-west-2"
# region = "us-east-1"

# Network Configuration
# vpc_cidr             = "10.0.0.0/8"
# vpc_cidr             = "172.16.0.0/12"
vpc_cidr = "192.168.0.0/16"

public_subnet_count  = 2
private_subnet_count = 2

# Project Configuration
project_name = "pge"
environment  = "dev"

# EC2 Configuration
# key_name is now auto-generated and stored in KMS

# Database Configuration
# db_password is now auto-generated and stored in KMS
# instance_class = "db.r6g.large"
instance_class = "db.t4g.medium"
instance_count = 2
db_username    = "pg_admin"

# ECR Configuration
repository_name = "pge-repo"
# Container Configuration
container_image = "nginx:latest"
# container_image = "831926591886.dkr.ecr.us-west-2.amazonaws.com/pge-infrastructure-app:latest"

alert_email_address = "bhavanisankar.pendem@trianz.com"
