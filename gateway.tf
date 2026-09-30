resource "aws_ecr_repository" "gateway" {
  name                 = "${var.project_name}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecs_cluster" "gateway" {
  name = var.project_name
}

resource "aws_cloudwatch_log_group" "gateway" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 30
}

locals {
  gateway_config_hash = substr(filesha256("${path.module}/gateway-image/gateway.yaml"), 0, 8)
  gateway_image_tag   = "${var.gateway_version}-cfg${local.gateway_config_hash}"
}

output "ecr_repository_url" {
  description = "ECR registry URL for the gateway container image."
  value       = aws_ecr_repository.gateway.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster that will run the gateway service."
  value       = aws_ecs_cluster.gateway.name
}

output "gateway_log_group_name" {
  description = "CloudWatch log group for gateway container stdout and stderr."
  value       = aws_cloudwatch_log_group.gateway.name
}

output "gateway_image_tag" {
  description = "Immutable image tag derived from the pinned release and gateway config."
  value       = local.gateway_image_tag
}

output "gateway_image_uri" {
  description = "ECR image URI to build and push before creating the ECS service."
  value       = "${aws_ecr_repository.gateway.repository_url}:${local.gateway_image_tag}"
}