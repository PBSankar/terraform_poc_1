output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "load_balancer_dns" {
  value = aws_lb.public.dns_name
}

output "load_balancer_zone_id" {
  value = aws_lb.public.zone_id
}

output "service_name" {
  value = aws_ecs_service.app.name
}

output "alb_arn_suffix" {
  value = aws_lb.public.arn_suffix
}

# outputs.tf
output "alb_dns_name" {
  value = aws_lb.public.dns_name
}

output "alb_arn" {
  value = aws_lb.public.arn
}

output "tg_arn" {
  value = aws_lb_target_group.main.arn
}

output "target_group_name" {
  value = aws_lb_target_group.main.name
}

output "cluster_arn" {
  value = aws_ecs_cluster.main.arn
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.app.arn
}

output "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  description = "ECS task role ARN for application permissions"
  value       = aws_iam_role.ecs_task_role.arn
}

