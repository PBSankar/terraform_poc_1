# Generate random DB username
# resource "random_string" "db_username" {
#   length  = 16
#   special = false
#   upper   = false
# }

# Generate random DB password
resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store DB username in Secrets Manager
resource "aws_secretsmanager_secret" "db_username" {
  name                    = "${var.project_name}-${var.environment}-db-user"
  description             = "Database username"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 0
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db-username"
  })
}

resource "aws_secretsmanager_secret_version" "db_username" {
  secret_id     = aws_secretsmanager_secret.db_username.id
  # secret_string = random_string.db_username.result
  secret_string = var.db_username
}

# Store DB password in Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.project_name}-${var.environment}-db-passwd"
  description             = "Database password"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 0
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db-password"
  })
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-subnet-group"
  subnet_ids = var.private_subnet_ids
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  })
}

# RDS Aurora Cluster
resource "aws_rds_cluster" "main" {
  cluster_identifier      = "${var.project_name}-${var.environment}-aurora-cluster"
  engine                  = "aurora-mysql"
  engine_version          = "8.0.mysql_aurora.3.04.0"
  database_name           = var.database_name
  # master_username         = random_string.db_username.result
  master_username         = var.db_username
  master_password         = random_password.db_password.result
  backup_retention_period = 7
  preferred_backup_window = "07:00-09:00"
  
  vpc_security_group_ids = [var.security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  storage_encrypted = true
  kms_key_id        = var.kms_key_arn
  
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  
  skip_final_snapshot = true
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-aurora-cluster"
  })
}

# RDS Aurora Instances
resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = var.instance_count
  identifier         = "${var.project_name}-${var.environment}-aurora-instance-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version
  promotion_tier     = count.index
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-aurora-instance-${count.index + 1}"
    Role = count.index == 0 ? "writer" : "reader"
  })
}

# RDS Proxy for Connection Pooling
resource "aws_db_proxy" "main" {
  name                   = "${var.project_name}-${var.environment}-rds-proxy"
  engine_family          = "MYSQL"
  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret.db_password.arn
  }
  role_arn               = aws_iam_role.rds_proxy.arn
  vpc_subnet_ids         = var.private_subnet_ids
  require_tls            = true
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-rds-proxy"
  })
}

resource "aws_db_proxy_default_target_group" "main" {
  db_proxy_name = aws_db_proxy.main.name

  connection_pool_config {
    connection_borrow_timeout    = 120
    max_connections_percent      = 100
    max_idle_connections_percent = 50
  }
}

resource "aws_db_proxy_target" "main" {
  db_proxy_name         = aws_db_proxy.main.name
  target_group_name     = aws_db_proxy_default_target_group.main.name
  db_cluster_identifier = aws_rds_cluster.main.id
}

# IAM Role for RDS Proxy
resource "aws_iam_role" "rds_proxy" {
  name = "${var.project_name}-${var.environment}-rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-rds-proxy-role"
  })
}

resource "aws_iam_role_policy" "rds_proxy" {
  name = "${var.project_name}-${var.environment}-rds-proxy-policy"
  role = aws_iam_role.rds_proxy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.db_username.arn,
          aws_secretsmanager_secret.db_password.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = var.kms_key_arn
      }
    ]
  })
}