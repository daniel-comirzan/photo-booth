data "template_file" "task" {
  template = file("${path.module}/task_definition/${var.service}.tpl")
  vars = {
    env                = var.env_name
    log_group          = aws_cloudwatch_log_group.cw.name
    region             = var.region
    load_balancer_port = var.resources["container_port"]
    container_port     = var.resources["container_port"]
    cpu                = var.resources["cpu_reservation"]
    memory             = var.resources["memory_reservation"]
    image              = join(":", [aws_ecr_repository.ecr.arn, var.app_version])
    path               = var.healthcheck["path"]
    retry              = var.healthcheck["retry"]
    timeout            = var.healthcheck["timeout"]
    interval           = var.healthcheck["interval"]
    start_period       = var.healthcheck["start_period"]
  }
}