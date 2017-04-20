# Define our ECS cluster, for GoCD to launch agents onto.

data "aws_iam_policy_document" "ec2-sts-policy" {
  statement {
    actions = [
      "sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com"]
    }
  }
}

resource "aws_ecs_cluster" "gocd-agents-cluster" {
  name = "${var.environment}-gocd-agents"
}

resource "aws_cloudwatch_log_group" "agent-cluster-cloudwatch-log-group" {
  name = "${var.environment}-gocd-ecs"
  retention_in_days = 1
}

resource "aws_iam_role" "agent-role" {
  assume_role_policy = "${data.aws_iam_policy_document.ec2-sts-policy.json}"
  name_prefix = "gocd-ecs-agent"
}
