resource "aws_ecs_service" "gateway" {
  name            = var.project_name
  cluster         = aws_ecs_cluster.gateway.arn
  task_definition = aws_ecs_task_definition.gateway.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  platform_version = "LATEST"
  force_new_deployment = true

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 120

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.gateway.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.gateway.arn
    container_name   = var.project_name
    container_port   = 8080
  }

  depends_on = [
    aws_iam_role_policy.task_bedrock,
    aws_iam_role_policy.execution_secrets,
    aws_iam_role_policy_attachment.execution_managed,
    aws_lb_listener.https,
  ]
}

output "gateway_ecs_service_name" {
  description = "Fargate service running the Claude gateway."
  value       = aws_ecs_service.gateway.name
}