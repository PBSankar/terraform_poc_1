# alb.tf
resource "aws_lb" "public" {
  name               = "${var.project_name}-${var.environment}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [var.web_security_group_id]
  subnets            = var.public_subnet_ids

  idle_timeout = 60

  enable_deletion_protection = false
  enable_http2               = true
  drop_invalid_header_fields = true

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    enabled = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket" "alb_logs" {
  bucket = "${var.project_name}-${var.environment}-alb-logs-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-alb-logs"
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_elb_service_account" "main" {}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
      }
    ]
  })
}

# Target Group for ECS service (HTTP on port 80, health check '/')
resource "aws_lb_target_group" "main" {
  name        = "${var.project_name}-${var.environment}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"            # Fargate requires 'ip'
  deregistration_delay = 30

  health_check {
    enabled             = true
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    path                = "/"
    matcher             = "200-399"
    protocol            = "HTTP"
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-tg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Listener on HTTP(80)
# If ACM cert provided, we redirect HTTP -> HTTPS
# Otherwise, we forward HTTP directly to the target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = var.acm_certificate_arn != "" ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.acm_certificate_arn == "" ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.main.arn
    }
  }
}

# Optional HTTPS(443) Listener (requires ACM cert in same region)
resource "aws_lb_listener" "https" {
  count             = var.acm_certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.public.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
