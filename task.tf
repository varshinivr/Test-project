resource "aws_ecs_task_definition" "gateway" {
  family                   = var.project_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  lifecycle {
    create_before_destroy = true
  }

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = var.project_name
      image     = "${aws_ecr_repository.gateway.repository_url}:${local.gateway_image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      secrets = [
        {
          name      = "GATEWAY_JWT_SECRET"
          valueFrom = aws_secretsmanager_secret.gateway_jwt.arn
        },
        {
          name      = "OIDC_CLIENT_SECRET"
          valueFrom = aws_secretsmanager_secret.gateway_oidc_client.arn
        },
        {
          name      = "GATEWAY_POSTGRES_URL"
          valueFrom = "${aws_secretsmanager_secret_version.gateway_postgres_url.arn}:::${aws_secretsmanager_secret_version.gateway_postgres_url.version_id}"
        },
        {
          name      = "GATEWAY_POSTGRES_PASSWORD"
          valueFrom = "${aws_db_instance.gateway.master_user_secret[0].secret_arn}:password::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.gateway.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "gateway"
        }
      }
    }
  ])
}

output "gateway_task_definition_arn" {
  description = "Registered Fargate task definition for the Claude gateway."
  value       = aws_ecs_task_definition.gateway.arn
}