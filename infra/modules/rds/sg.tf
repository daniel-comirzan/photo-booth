resource "aws_security_group" "aurora" {
  name        = join("-", [var.env_name, "db-sg"])
  description = "Main Security Group for the Aurora cluster"
  vpc_id      = var.vpc_id
  tags = merge(
    map("Name", join("-", [var.env_name, "db-sg"])),
    var.common_tags
  )
}

resource "aws_security_group_rule" "aurora_ingress" {
  security_group_id = aws_security_group.aurora.id
  description       = "Allow connection to cluster port "
  protocol          = "tcp"
  from_port         = coalesce(var.port, local.port)
  to_port           = coalesce(var.port, local.port)
  type              = "ingress"
  self              = true
}

resource "aws_security_group_rule" "private_ingress" {
  count             = length(var.allowed_cidr) > 0 ? 1 : 0
  from_port         = coalesce(var.port, local.port)
  protocol          = "tcp"
  security_group_id = aws_security_group.aurora.id
  to_port           = var.port
  type              = "ingress"
  cidr_blocks       = var.allowed_cidr
}