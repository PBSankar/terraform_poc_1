# Example terraform.tfvars file
# Copy this to terraform.tfvars and modify as needed

# AWS Configuration
region = "us-west-2"
# region = "us-east-1"

# Network Configuration
# Examples for different VPC CIDR sizes:
# vpc_cidr = "10.0.0.0/8"   - Large network (16M IPs) - auto-calculates /12 subnets (1M IPs each)
# vpc_cidr = "172.16.0.0/12" - Medium network (1M IPs) - auto-calculates /16 subnets (65K IPs each)
# vpc_cidr = "192.168.0.0/16" - Small network (65K IPs) - auto-calculates /18 subnets (16K IPs each)
# vpc_cidr = "10.0.0.0/20"   - Tiny network (4K IPs) - auto-calculates /22 subnets (1K IPs each)
vpc_cidr = "192.168.0.0/16"

public_subnet_count  = 2
private_subnet_count = 2

# Optional: Specify custom subnet CIDRs (if not provided, will be auto-calculated)
# For /16 VPC with 4 subnets, auto-calculated CIDRs will be:
# public_subnet_cidrs  = ["192.168.0.0/18", "192.168.64.0/18"]
# private_subnet_cidrs = ["192.168.128.0/18", "192.168.192.0/18"]

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

# ECR Image Versioning
# ecr_image_version = "1.02"  # Specify version (e.g., 1.0, 1.02, 2.5) or leave empty for auto-increment
# ecr_source_image  = "nginx:latest"  # Source image to push to ECR

# Container Configuration
container_image = "nginx:latest"
# container_image = "831926591886.dkr.ecr.us-west-2.amazonaws.com/pge-infrastructure-app:latest"

# ECS Task Configuration
# ecs_task_cpu       = 256   # 256, 512, 1024, 2048, 4096
# ecs_task_memory    = 512   # 512, 1024, 2048, 4096, 8192
# ecs_container_name = "app" # Meaningful name for your application
# Valid Combinations:
# CPU	Memory Options (MiB)
# 256	512, 1024, 2048
# 512	1024-4096
# 1024	2048-8192
# 2048	4096-16384
# 4096	8192-30720

# ECS Autoscaling Configuration
# ecs_desired_count  = 2     # Initial number of tasks
# ecs_min_capacity   = 1     # Minimum tasks during scale-in
# ecs_max_capacity   = 10    # Maximum tasks during scale-out

alert_email_address = "bhavanisankar.pendem@trianz.com"

github_repo_url         = "https://github.com/PBSankar/terraform_poc_1.git"
github_branch           = "main"
github_token = ""
