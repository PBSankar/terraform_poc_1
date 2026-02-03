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
  drop_invalid_header_fields  = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Target Group for ECS service (HTTP on port 80, health check '/')
resource "aws_lb_target_group" "main" {
  name        = "${var.project_name}-${var.environment}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"            # Fargate requires 'ip'

  health_check {
    enabled             = true
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    path                = "/"
    matcher             = "200-399"
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
