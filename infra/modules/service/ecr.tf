resource "aws_ecr_repository" "ecr" {
  name = join("-", [var.env_name, var.service, "ecr"])
  tags = var.common_tags
}