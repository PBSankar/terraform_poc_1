locals {
  interface_endpoints = {
    ecr_dkr        = "ecr.dkr"
    ecr_api        = "ecr.api"
    logs           = "logs"
    monitoring     = "monitoring"
    ecs            = "ecs"
    secretsmanager = "secretsmanager"
    sts            = "sts"
    ssm            = "ssm"
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoints

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids = [var.vpc_endpoint_security_group_id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${each.key}-endpoint"
    Environment = var.environment
  })
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids

  tags = merge(var.tags, {
    Name        = "${var.project_name}-s3-endpoint"
    Environment = var.environment
  })
}
