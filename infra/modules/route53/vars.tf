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