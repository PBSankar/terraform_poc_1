# resource "aws_security_group" "web" {
#   name_prefix = "${var.project_name}-${var.environment}-web"
#   vpc_id      = var.vpc_id

#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   # Optional: keep only if you use ALB redirect
#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port       = 443
#     to_port         = 443
#     protocol        = "tcp"
#     security_groups = [aws_security_group.app.id]
#   }

#   tags = {
#     Name        = "${var.project_name}-${var.environment}-web-sg"
#     Environment = var.environment
#   }
# }

# resource "aws_security_group" "app" {
#   name_prefix = "${var.project_name}-${var.environment}-app"
#   vpc_id      = var.vpc_id

#   ingress {
#     from_port       = 8080
#     to_port         = 8080
#     protocol        = "tcp"
#     security_groups = [aws_security_group.web.id]
#   }

#   egress {
#     from_port       = 5432
#     to_port         = 5432
#     protocol        = "tcp"
#     security_groups = [aws_security_group.database.id]
#   }

#   egress {
#     from_port       = 443
#     to_port         = 443
#     protocol        = "tcp"
#     security_groups = [aws_security_group.vpc_endpoint.id]
#   }

#   tags = {
#     Name        = "${var.project_name}-app-sg"
#     Environment = var.environment
#   }
# }

# resource "aws_security_group" "database" {
#   name_prefix = "${var.project_name}-${var.environment}-db"
#   vpc_id      = var.vpc_id

#   ingress {
#     from_port       = 5432
#     to_port         = 5432
#     protocol        = "tcp"
#     security_groups = [aws_security_group.app.id]
#   }

#   egress {
#     from_port       = 0
#     to_port         = 0
#     protocol        = "-1"
#     security_groups = [aws_security_group.app.id]
#   }

#   tags = {
#     Name        = "${var.project_name}-db-sg"
#     Environment = var.environment
#   }
# }

# resource "aws_security_group" "vpc_endpoint" {
#   name_prefix = "${var.project_name}-${var.environment}-vpc-endpoint"
#   vpc_id      = var.vpc_id

#   ingress {
#     from_port       = 443
#     to_port         = 443
#     protocol        = "tcp"
#     security_groups = [aws_security_group.app.id]
#   }

#   egress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name        = "${var.project_name}-vpc-endpoint-sg"
#     Environment = var.environment
#   }
# }

# resource "aws_network_acl" "public" {
#   vpc_id     = var.vpc_id
#   subnet_ids = var.public_subnet_ids

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 80
#     to_port    = 80
#   }

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 110
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 443
#     to_port    = 443
#   }

#   egress {
#     protocol   = "-1"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 0
#     to_port    = 0
#   }

#   tags = {
#     Name        = "${var.project_name}-public-nacl"
#     Environment = var.environment
#   }
# }

# resource "aws_network_acl" "private" {
#   vpc_id     = var.vpc_id
#   subnet_ids = var.private_subnet_ids

#   # ALB → ECS
#   ingress {
#     rule_no    = 100
#     protocol   = "tcp"
#     action     = "allow"
#     cidr_block = var.vpc_cidr
#     from_port  = 8080
#     to_port    = 8080
#   }

#   # Return traffic
#   ingress {
#     rule_no    = 110
#     protocol   = "tcp"
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 1024
#     to_port    = 65535
#   }

#   # Outbound to DB + AWS services
#   egress {
#     rule_no    = 100
#     protocol   = "tcp"
#     action     = "allow"
#     cidr_block = var.vpc_cidr
#     from_port  = 5432
#     to_port    = 5432
#   }

#   egress {
#     rule_no    = 110
#     protocol   = "tcp"
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 443
#     to_port    = 443
#   }

#   tags = {
#     Name        = "${var.project_name}-private-nacl"
#     Environment = var.environment
#   }
# }

#########################################################
resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-${var.environment}-web"
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = true

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-web-sg"
    Environment = var.environment
  })
}

resource "aws_security_group" "app" {
  name_prefix = "${var.project_name}-${var.environment}-app"
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = true

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-app-sg"
    Environment = var.environment
  })
}

resource "aws_security_group" "database" {
  name_prefix = "${var.project_name}-${var.environment}-db"
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = true

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-db-sg"
    Environment = var.environment
  })
}

resource "aws_security_group" "vpc_endpoint" {
  name_prefix = "${var.project_name}-${var.environment}-vpc-endpoint"
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = true

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-vpc-endpoint-sg"
    Environment = var.environment
  })
}


resource "aws_security_group_rule" "web_https_in" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web.id
  
  depends_on = [aws_security_group.web]
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "web_http_in" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web.id
  
  depends_on = [aws_security_group.web]
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "web_to_app" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.web.id
  
  depends_on = [aws_security_group.web, aws_security_group.app]
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "app_from_web" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web.id
  security_group_id        = aws_security_group.app.id
  
  depends_on = [aws_security_group.web, aws_security_group.app]
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "app_to_db" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.database.id
  security_group_id        = aws_security_group.app.id
  
  depends_on = [aws_security_group.app, aws_security_group.database]
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "app_to_endpoints" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.vpc_endpoint.id
  security_group_id        = aws_security_group.app.id
  
  depends_on = [aws_security_group.app, aws_security_group.vpc_endpoint]
  
  lifecycle {
    create_before_destroy = true
  }
}

# Allow app to access internet for Docker image pulls
resource "aws_security_group_rule" "app_to_internet" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app.id
  
  depends_on = [aws_security_group.app]
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "db_from_app" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.database.id
  
  depends_on = [aws_security_group.app, aws_security_group.database]
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "endpoint_from_app" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.vpc_endpoint.id
  
  depends_on = [aws_security_group.app, aws_security_group.vpc_endpoint]
  
  lifecycle {
    create_before_destroy = true
  }
}



### NACL
resource "aws_network_acl" "public" {
  vpc_id     = var.vpc_id
  subnet_ids = var.public_subnet_ids

  # Allow ALL inbound traffic
  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Allow ALL outbound traffic
  egress {
    protocol   = "-1"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  lifecycle {
    create_before_destroy = true
  }
  
  tags = merge(var.tags, {
    Name        = "${var.project_name}-public-nacl"
    Environment = var.environment
  })
}

resource "aws_network_acl" "private" {
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # Allow ALL inbound traffic
  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Allow ALL outbound traffic
  egress {
    protocol   = "-1"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-private-nacl"
    Environment = var.environment
  })
}



