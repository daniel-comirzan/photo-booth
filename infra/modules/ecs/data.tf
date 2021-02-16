data "aws_ami" "amazon_linux_ecs" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

data "template_file" "ecs_user_data" {
  template = file("${path.module}/user_data/ecs-user-data.sh")
  vars = {
    cluster_name = aws_ecs_cluster.ecs.name
  }
}

data "aws_availability_zones" "current" {}