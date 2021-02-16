#################################
# Autoscaling details
#################################

resource "aws_appautoscaling_target" "autoscaling" {
  max_capacity       = var.scaling_resources["max_size"]
  min_capacity       = var.scaling_resources["min_size"]
  resource_id        = join("/", ["service", var.ecs_cluster, aws_ecs_service.ecs_service.name])
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "autoscaling" {
  name               = join("-", [var.env_name, var.service])
  resource_id        = aws_appautoscaling_target.autoscaling.resource_id
  scalable_dimension = aws_appautoscaling_target.autoscaling.scalable_dimension
  service_namespace  = aws_appautoscaling_target.autoscaling.service_namespace
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.scaling_resources["cpu_threshold"]
    scale_in_cooldown  = var.scaling_resources["scale_in_cooldown"]
    scale_out_cooldown = var.scaling_resources["scale_out_cooldown"]
  }
}