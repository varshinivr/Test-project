resource "aws_secretsmanager_secret" "gateway_jwt" {
  name = "claude-gateway-jwt-secret"
}

resource "aws_secretsmanager_secret" "gateway_oidc_client" {
  name = "claude-gateway-oidc-client-secret"
}

resource "aws_secretsmanager_secret" "gateway_postgres_url" {
  name = "claude-gateway-postgres-url"
}

resource "aws_secretsmanager_secret_version" "gateway_postgres_url" {
  secret_id                = aws_secretsmanager_secret.gateway_postgres_url.id
  secret_string_wo         = "postgres://${aws_db_instance.gateway.address}:5432/${aws_db_instance.gateway.db_name}?sslmode=verify-full"
  secret_string_wo_version = 1
}

output "gateway_secret_arns" {
  description = "Secrets Manager ARNs whose values are supplied separately from Terraform."
  value = {
    jwt          = aws_secretsmanager_secret.gateway_jwt.arn
    oidc_client  = aws_secretsmanager_secret.gateway_oidc_client.arn
    postgres_url = aws_secretsmanager_secret.gateway_postgres_url.arn
  }
}