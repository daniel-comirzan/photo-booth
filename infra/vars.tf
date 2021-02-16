variable "region_short_name" {
  type = map(string)

  default = {
    eu-central-1   = "FRA"
    eu-west-1      = "DUB"
    us-east-1      = "VIR"
    us-west-1      = "CAL"
    us-west-2      = "ORE"
    ap-southeast-1 = "SIN"
    ap-southeast-2 = "SYD"
    ap-south-1     = "MUM"
  }
}

variable "account_id" {
  type        = string
  description = "The Account ID."
}

variable "region" {
  type        = string
  description = "The used AWS region."
}

variable "env" {
  type        = string
  description = "Environment type [ d / t / s / l]"
  default     = "d"
}

variable "customer" {
  type        = string
  default     = "devops"
  description = "The customer using the environment"
}

variable "product" {
  type        = string
  default     = "photo-booth"
  description = "Product name"
}

variable "owner" {
  type        = string
  default     = "developer"
  description = "The developer name"
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR used by the VPC"
}

variable "frontend_version" {
  type    = string
  default = "0.0.3"
}

variable "backend_version" {
  type    = string
  default = "0.0.2"
}

variable "db_username" {
  type        = string
  default     = "app_db_user"
  description = "The db username"
}

variable "db_engine_version" {
  type        = string
  description = "The db engine version"
  default     = "11.8"
}