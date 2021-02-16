variable "env_name" {
  type        = string
  description = "The name of the environment.  This will be used as the tag name for all resources created (that support tagging)."
}

variable "owner" {
  type        = string
  description = "The owner of our AWS environment"
}

variable "region" {
  type        = string
  description = "The AWS region we want to install all our environment.  Must be a region with 3 availability-zones"
}

variable "account_id" {
  type        = string
  description = "Account Id"
  default     = ""
}

variable "logs_bucket" {
  type = string
  description = "The bucket in which all logs are saved."
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR to use for this environment's VPC.  This should be a /22 to follow the SPS/SOC's standards"
}

variable "enable_public_subnet" {
  type        = bool
  description = "Define if public subnets are needed or not ( HSM example ) "
  default     = true
}

variable "enable_sns" {
  type        = bool
  description = "Enable notification service"
  default     = false
}

variable "sns_email_subscribers" {
  type        = list
  description = "List of subscribers to the sns topic"
  default     = [""]
}

variable "enable_cloudtrail" {
  type        = bool
  description = "Enable CloudTrail for monitoring purposes"
  default     = false
}

variable "subnet_count" {
  type        = number
  description = "limit the number of subnets"
  default     = 0
}

variable "common_tags" {
  type        = map
  default     = {}
  description = "The tags used in the rest of the project"
}

variable "enable_vpc_peering" {
  type        = bool
  description = "Enable creation of management VPC peering connection"
  default     = false
}

variable "remote_account_id" {
  type = string
  default = ""
}
variable "remote_account_peering_id" {
  type = string
  default = ""
}