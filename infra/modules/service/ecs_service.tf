resource "aws_ecs_task_definition" "td" {
  family                = join("-", [var.env_name, var.service])
  container_definitions = data.template_file.task.rendered

  requires_compatibilities = ["EC2"]
  memory                   = var.resources["memory_reservation"]
  cpu                      = var.resources["cpu_reservation"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  tags = merge(
    map("Name", join("-", [var.env_name, var.service])),
    var.common_tags
  )
}

resource "aws_ecs_service" "ecs_service" {
  name                              = join("-", [var.env_name, var.service])
  cluster                           = var.ecs_cluster
  task_definition                   = aws_ecs_task_definition.td.arn
  launch_type                       = "FARGATE"
  desired_count                     = var.scaling_resources["desired_size"]
  health_check_grace_period_seconds = "30"

  network_configuration {
    subnets = var.subnets
    security_groups = [
    aws_security_group.lb_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = var.env_name
    container_port   = var.resources["container_port"]
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = merge(
    map("Name", join("-", [var.env_name, var.service])),
    var.common_tags
  )
}