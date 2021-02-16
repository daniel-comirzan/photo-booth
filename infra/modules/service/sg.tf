resource "aws_security_group" "lb_sg" {
  //  name        = "${var.env}-${var.product}-sg"
  name        = join("-", [var.env_name, var.service, "lb-sg"])
  vpc_id      = var.vpc_id
  description = "Security group for the Load Balancer"

  tags = merge(
    map("Name", join("-", [var.env_name, var.service, "lb-sg"])),
    var.common_tags
  )
}

resource "aws_security_group_rule" "public_access_lb" {
  from_port         = lookup(var.resources, "load_balancer_port")
  to_port           = lookup(var.resources, "load_balancer_port")
  protocol          = local.lb_protocol
  security_group_id = aws_security_group.lb_sg.id
  cidr_blocks       = local.lb_access
  type              = "ingress"
}

resource "aws_security_group_rule" "lb_outbound" {
  from_port         = 0
  to_port           = 65535
  protocol          = "TCP"
  security_group_id = aws_security_group.lb_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "egress"
}

resource "aws_security_group" "app_sg" {
  name        = join("-", [var.env_name, var.service, "app-sg"])
  vpc_id      = var.vpc_id
  description = "Security group for the application"

  tags = merge(
    map("Name", join("-", [var.env_name, var.service, "app-sg"])),
    var.common_tags
  )
}

resource "aws_security_group_rule" "private_access_app" {
  from_port         = lookup(var.resources, "container_port")
  to_port           = lookup(var.resources, "container_port")
  protocol          = "HTTP"
  security_group_id = aws_security_group.app_sg.id
  cidr_blocks       = var.subnets
  type              = "ingress"
}

resource "aws_security_group_rule" "app_outbound" {
  from_port         = 0
  to_port           = 65535
  protocol          = "TCP"
  security_group_id = aws_security_group.app_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "egress"
}