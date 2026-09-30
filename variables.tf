variable "project_name" {
  description = "Prefix for resource names."
  type        = string
  default     = "claude-gateway"
}

variable "region" {
  description = "AWS region. Must be a US region where Bedrock serves Claude."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "Address range of the new VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "domain_name" {
  description = "Registered domain (public Route 53 hosted zone already exists for it)."
  type        = string
  default     = "claudegw-lab-test.click"
}

variable "gateway_hostname" {
  description = "Hostname developers use to reach the gateway."
  type        = string
  default     = "claude-gateway.claudegw-lab-test.click"
}

variable "db_engine_version" {
  description = "Pinned PostgreSQL major/minor version for the lab database."
  type        = string
  default     = "16.15"
}

variable "db_instance_class" {
  description = "Smallest practical RDS instance class for the lab."
  type        = string
  default     = "db.t4g.micro"
}

variable "bastion_instance_type" {
  description = "Small ARM burstable instance used only for SSM port forwarding."
  type        = string
  default     = "t4g.nano"
}

variable "gateway_version" {
  description = "Pinned Claude Code release used for the gateway image."
  type        = string
  default     = "2.1.284"
}
