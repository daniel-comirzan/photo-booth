

resource "aws_lb" "service" {
  name = join("-", [var.env_name, var.service])

  internal        = local.lb_internal
  subnets         = var.subnets
  security_groups = [aws_security_group.lb_sg.id]

  enable_cross_zone_load_balancing = "true"
  idle_timeout                     = "60"
  ip_address_type                  = "ipv4"

  access_logs {
    bucket = var.logs_bucket
    prefix  = var.service
    enabled = true
  }

  tags = var.common_tags
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.service.arn
  port              = var.resources["load_balancer_port"]
  protocol          = local.lb_protocol
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_target_group" "tg" {
  name                 = join("-", [var.env_name, var.service, "tg"])
  port                 = var.container_port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = "60"
  depends_on           = [aws_lb.service]

  health_check {
    path                = var.healthcheck["path"]
    timeout             = var.healthcheck["timeout"]
    healthy_threshold   = var.healthcheck["healthy_threshold"]
    unhealthy_threshold = var.healthcheck["unhealthy_threshold"]
    interval            = var.healthcheck["interval"]
    matcher             = var.healthcheck["matcher"]
    port                = var.container_port
  }

  lifecycle {
    create_before_destroy = true
  }

  stickiness {
    type    = "lb_cookie"
    enabled = false
  }

  tags = merge(
    map("Name", join("-", [var.env_name, var.service, "tg"])),
    var.common_tags
  )
}