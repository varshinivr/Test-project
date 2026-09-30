resource "aws_db_subnet_group" "gateway" {
  name       = "${var.project_name}-db"
  subnet_ids = aws_subnet.private[*].id

  tags = { Name = "${var.project_name}-db" }
}

resource "aws_db_parameter_group" "gateway" {
  name   = "${var.project_name}-postgres16"
  family = "postgres16"

  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
  }
}

resource "aws_db_instance" "gateway" {
  identifier                 = var.project_name
  engine                     = "postgres"
  engine_version             = var.db_engine_version
  instance_class             = var.db_instance_class
  allocated_storage          = 20
  storage_type               = "gp3"
  storage_encrypted          = true
  db_name                    = "claude_gateway"
  username                   = "gateway_admin"
  manage_master_user_password = true
  parameter_group_name       = aws_db_parameter_group.gateway.name
  db_subnet_group_name       = aws_db_subnet_group.gateway.name
  vpc_security_group_ids     = [aws_security_group.db.id]
  publicly_accessible        = false
  multi_az                   = false
  backup_retention_period    = 0
  auto_minor_version_upgrade = true
  deletion_protection        = false
  skip_final_snapshot        = true
}

output "database_endpoint" {
  description = "Private PostgreSQL endpoint; reachable only from the VPC."
  value       = aws_db_instance.gateway.address
}

output "database_master_secret_arn" {
  description = "AWS-managed secret ARN for the database administrator password."
  value       = aws_db_instance.gateway.master_user_secret[0].secret_arn
}

output "private_subnet_ids" {
  description = "Subnet IDs reserved for private resources such as PostgreSQL."
  value       = aws_subnet.private[*].id
}