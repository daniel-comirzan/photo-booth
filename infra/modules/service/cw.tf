resource "aws_cloudwatch_log_group" "cw" {
  name = join("/", ["", "ecs", var.env_name, var.service])

  tags = var.common_tags
}