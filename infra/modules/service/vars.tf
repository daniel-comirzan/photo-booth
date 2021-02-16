variable "env_name" {
  type        = string
  description = "The environment name"
}

variable "region" {
  type        = string
  description = "Region in which the environment is deployed"
}

variable "common_tags" {
  type = map
}

variable "service" {
  type = string
  description = "Component to be deployed. Available values [ backend / frontend ]"
}

variable "ecs_cluster" {
  type = string
  description = "The cluster used to create the service"
}

variable "app_version" {
  type = string
  description = "Application tag"
}

variable "load_balancer_port" {
  type = number
  description = "The default application port"
  default = 443
}

variable "container_port" {
  type = number
  description = "The default application port"
  default = 8080
}

variable "cpu_reservation" {
  type = number
  description = "The amount of CPU assigned to each container"
  default = 1024
}

variable "resources" {
  type = map
  default = {
    load_balancer_port: 443
    container_port: 8080
    cpu_reservation: 1024
    memory_reservation: 2048
  }
}

variable "scaling_resources" {
  type = map
  default = {
    min_size: 1
    max_size: 2
    desired_size:1
    cpu_threshold: 60
    scale_in_cooldown: 300
    scale_out_cooldown: 60
  }
}

variable "healthcheck" {
  type = map
  default = {
    retry : 3
    timeout : 30
    healthy_threshold : 2
    unhealthy_threshold : 3
    interval : 120
    start_period : 300
    matcher : "200-399"
    path: "/healthcheck"
  }
}

variable "subnets" {
  type = list
  description = "The subnet where the service will be deployed"
}

variable "vpc_id" {
  type = string
  description = "VPC ID"
}

variable "access_cidr" {
  type = list
  description = "Access to application"
}

variable "external_lb_access_cidr" {
  type = list
  default = ["0.0.0.0/0"]
}

variable "logs_bucket" {
  type = string
  description = "The bucket storing the LB logs"
}