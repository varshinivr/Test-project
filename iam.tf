data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  # Secrets Manager appends a random 6-char suffix to every secret ARN, so
  # "-??????" matches exactly that suffix. Names are created in a later step.
  secret_arns = concat(
    [
      for name in ["claude-gateway-jwt-secret", "claude-gateway-oidc-client-secret", "claude-gateway-postgres-url"] :
      "arn:aws:secretsmanager:${var.region}:${local.account_id}:secret:${name}-??????"
    ],
    [aws_db_instance.gateway.master_user_secret[0].secret_arn]
  )
}

# Both ECS roles are assumed by the ECS service itself, so they share one trust policy.
data "aws_iam_policy_document" "ecs_tasks_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ---------- Task role: what the RUNNING gateway may do (call Bedrock) ----------
resource "aws_iam_role" "task" {
  name               = "${var.project_name}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json
}

data "aws_iam_policy_document" "bedrock_invoke" {
  statement {
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
      "bedrock:CountTokens",
    ]
    resources = [
      # Cross-region inference profiles (the gateway's default model IDs are us.anthropic.*)...
      "arn:aws:bedrock:${var.region}:${local.account_id}:inference-profile/us.anthropic.*",
      # ...which fan out to the underlying foundation models in any US region.
      "arn:aws:bedrock:*::foundation-model/anthropic.*",
    ]
  }
}

resource "aws_iam_role_policy" "task_bedrock" {
  name   = "bedrock-invoke"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.bedrock_invoke.json
}

# ---------- Execution role: what ECS itself needs to START the task ----------
resource "aws_iam_role" "execution" {
  name               = "${var.project_name}-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json
}

# AWS-managed policy: pull from ECR + write to CloudWatch Logs.
resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "read_secrets" {
  statement {
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = local.secret_arns
  }
}

resource "aws_iam_role_policy" "execution_secrets" {
  name   = "read-gateway-secrets"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.read_secrets.json
}

# ---------- Bastion role: lets SSM Session Manager reach the EC2 instance ----------
data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bastion" {
  name               = "${var.project_name}-bastion"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2 can't use a role directly; it needs an instance profile wrapper.
resource "aws_iam_instance_profile" "bastion" {
  name = "${var.project_name}-bastion"
  role = aws_iam_role.bastion.name
}
