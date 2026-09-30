# Traffic chain: bastion -> ALB (443) -> gateway task (8080) -> Postgres (5432)

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb"
  description = "Internal ALB"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group" "gateway" {
  name        = "${var.project_name}-svc"
  description = "Gateway Fargate tasks"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group" "db" {
  name        = "${var.project_name}-db"
  description = "Gateway Postgres"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion"
  description = "SSM-only bastion, no inbound rules"
  vpc_id      = aws_vpc.main.id
}

# ALB: HTTPS only from the bastion. Nothing else in the VPC or internet can reach it.
resource "aws_vpc_security_group_ingress_rule" "alb_from_bastion" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.bastion.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
}

resource "aws_vpc_security_group_egress_rule" "alb_to_gateway" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.gateway.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
}

# Gateway: 8080 only from the ALB. Egress is open because it must reach
# ECR, Secrets Manager, Bedrock, Google and RDS (no NAT, so via its public IP).
resource "aws_vpc_security_group_ingress_rule" "gateway_from_alb" {
  security_group_id            = aws_security_group.gateway.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
}

resource "aws_vpc_security_group_egress_rule" "gateway_all" {
  security_group_id = aws_security_group.gateway.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# DB: Postgres only from the gateway.
resource "aws_vpc_security_group_ingress_rule" "db_from_gateway" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = aws_security_group.gateway.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

# Bastion: no inbound at all (SSM connects outbound from the instance).
resource "aws_vpc_security_group_egress_rule" "bastion_all" {
  security_group_id = aws_security_group.bastion.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
