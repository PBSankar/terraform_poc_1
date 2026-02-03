# ecs.tf
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"
}

resource "aws_ecs_task_definition" "app" {

  family                   = "${var.project_name}-${var.environment}-app-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"   # vCPU units
  memory                   = "512"   # MiB
  execution_role_arn       = var.execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "nginx:latest"
      essential = true
      portMappings = [{
        containerPort = 80
        hostPort      = 80
        protocol      = "tcp"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "nginx"
        }
      }
    }
  ])
}


resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-${var.environment}-app-svc"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.app_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "nginx"
    container_port   = 80
  }

  depends_on = [
    aws_ecs_task_definition.app,
    aws_lb_listener.http,
    aws_lb_target_group.main
  ]
}