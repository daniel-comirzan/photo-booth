resource "aws_ecs_cluster" "ecs" {
  name = join("-", [var.env_name, "ecs"])

//  capacity_providers = ["FARGATE", "FARGATE_SPOT", aws_ecs_capacity_provider.ecs.name]
//
//  default_capacity_provider_strategy = [{
//    capacity_provider = aws_ecs_capacity_provider.ecs.name
//    weight            = "1"
//  }]

  setting {
    name  = "containerInsights"
    value = var.container_insights ? "enabled" : "disabled"
  }

  tags = var.common_tags
}

resource "aws_launch_configuration" "ecs" {
  name_prefix = join(
    "-",
    [
      var.env_name,
      "ecs", ""
    ],
  )
  image_id             = data.aws_ami.amazon_linux_ecs.id
  instance_type        = var.ec2_instance_type
  key_name             = aws_key_pair.aws_keypair.id
  iam_instance_profile = aws_iam_instance_profile.ecs.id
  user_data            = data.template_file.ecs_user_data.rendered

  dynamic "root_block_device" {
    for_each = var.root_block_device
    content {
      delete_on_termination = lookup(root_block_device.value, "delete_on_termination", null)
      iops                  = lookup(root_block_device.value, "iops", null)
      volume_size           = lookup(root_block_device.value, "volume_size", null)
      volume_type           = lookup(root_block_device.value, "volume_type", null)
      encrypted             = lookup(root_block_device.value, "encrypted", null)
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs" {
  name_prefix = join(
    "-",
    [
      var.env_name,
      element(concat(random_id.asg_name.*.id, [""]), 0), ""
    ],
  )

  health_check_type = "EC2"

  max_size            = lookup(var.asg_size, "max_size", 6)
  min_size            = lookup(var.asg_size, "min_size", 2)
  desired_capacity    = lookup(var.asg_size, "desired_size", 2)
  vpc_zone_identifier = var.private_subnets

  launch_configuration = aws_launch_configuration.ecs.id

  lifecycle {
    create_before_destroy = true
  }

  dynamic "tag" {
    for_each = var.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  tag {
    key                 = "Name"
    propagate_at_launch = false
    value               = join("-", [var.env_name, "ecs"])
  }
  tag {
    key                 = "AmazonECSManaged"
    propagate_at_launch = true
    value               = ""
  }

}

//resource "aws_ecs_capacity_provider" "ecs" {
//  name = join("-", [var.env_name, "provider"])
//  auto_scaling_group_provider {
//    auto_scaling_group_arn = aws_autoscaling_group.ecs.arn
//    managed_termination_protection = "ENABLED"
//  }
//}

resource "aws_autoscaling_policy" "haproxy_autoscale" {
  name                   = join("-", [var.env_name, "autoscale"])
  autoscaling_group_name = aws_autoscaling_group.ecs.name
  estimated_instance_warmup = lookup(var.asg_size, "instance_cooldown")
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = lookup(var.asg_size, "cpu_threshold")
  }
}

resource "random_id" "asg_name" {
  byte_length = 8
  keepers = {
    # Generate a new pet name each time we switch launch configuration
    lc_name = aws_launch_configuration.ecs.name
  }
}