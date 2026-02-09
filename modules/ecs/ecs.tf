# ecs.tf
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-${var.environment}-app-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.image
      essential = true
      portMappings = [{
        containerPort = 80
        hostPort      = 80
        protocol      = "tcp"
      }]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.region
          awslogs-stream-prefix = var.container_name
        }
      }
    }
  ])
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-app-task"
  })

}


resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-${var.environment}-app-svc"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  health_check_grace_period_seconds = 60

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.app_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = var.container_name
    container_port   = 80
  }
  
  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [
    aws_ecs_task_definition.app,
    aws_lb_listener.http,
    aws_lb_target_group.main
  ]
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-app-svc"
  })
}

# Autoscaling Target
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Autoscaling Policy - CPU
resource "aws_appautoscaling_policy" "ecs_cpu" {
  name               = "${var.project_name}-${var.environment}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.cpu_target_value
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Autoscaling Policy - Memory
resource "aws_appautoscaling_policy" "ecs_memory" {
  name               = "${var.project_name}-${var.environment}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.memory_target_value
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Autoscaling Policy - ALB Request Count
resource "aws_appautoscaling_policy" "ecs_alb_requests" {
  name               = "${var.project_name}-${var.environment}-alb-request-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.public.arn_suffix}/${aws_lb_target_group.main.arn_suffix}"
    }
    target_value       = var.alb_request_count_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Scheduled Scaling - Scale up during business hours
resource "aws_appautoscaling_scheduled_action" "scale_up" {
  name               = "${var.project_name}-${var.environment}-scale-up"
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  schedule           = "cron(0 8 ? * MON-FRI *)"

  scalable_target_action {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }
}

# Scheduled Scaling - Scale down after business hours
resource "aws_appautoscaling_scheduled_action" "scale_down" {
  name               = "${var.project_name}-${var.environment}-scale-down"
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  schedule           = "cron(0 18 ? * MON-FRI *)"

  scalable_target_action {
    min_capacity = 1
    max_capacity = var.max_capacity
  }
}