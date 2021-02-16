data "aws_iam_policy_document" "ecs_instance_role" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type = "Service"
    }
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecs_instance_role" {
  name = join("-", [var.env_name, "instance-policy"])
  policy = data.aws_iam_policy_document.ecs_instance_role.json
}

resource "aws_iam_role" "ecs_instance_role" {
  name = join("-", [var.env_name, "instance-role"])
  path = "/ecs/"
  assume_role_policy = aws_iam_policy.ecs_instance_role.id
}

resource "aws_iam_instance_profile" "ecs" {
  name = join("-", [var.env_name, "instance-profile"])
  role = aws_iam_role.ecs_instance_role.name
}