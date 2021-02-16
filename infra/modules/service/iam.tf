data "aws_iam_policy_document" "ecs_role_document" {
  statement {
    sid    = ""
    effect = "Allow"
    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

###############################################
# Execution role and policy
###############################################

resource "aws_iam_role" "ecs_execution" {
  name               = join("-", [var.env_name, var.service, "execution", "role"])
  assume_role_policy = data.aws_iam_policy_document.ecs_role_document.json

  tags = merge(
    map("Name", join("-", [var.env_name, var.service, "execution", "role"])),
    var.common_tags
  )
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_execution.name
}

###############################################
# Task role and policy
###############################################

data "aws_iam_policy_document" "ecs_task" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter",
      "ssm:DescribeParameters",
      "ssm:DescribeParameter",
      "ssm:GetParametersByPath",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:*",
      "logs:*",
      "ecs:RunTask",
      "ecs:UpdateService",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetAuthorizationToken",
    ]
  }


}

resource "aws_iam_role" "ecs_task" {
  name               = join("-", [var.env_name, var.service, "task", "role"])
  assume_role_policy = data.aws_iam_policy_document.ecs_role_document.json

  tags = merge(
    map("Name", join("-", [var.env_name, var.service, "task", "role"])),
    var.common_tags
  )
}

resource "aws_iam_role_policy" "ecs_task" {
  name = join("-", [var.env_name, var.service, "task", "policy"])
  role = aws_iam_role.ecs_task.id

  policy = data.aws_iam_policy_document.ecs_task.json

}