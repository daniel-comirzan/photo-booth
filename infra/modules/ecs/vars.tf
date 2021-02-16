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

# Autoscaling group configuration

variable "ec2_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "asg_size" {
  type = map
  default = {
    min_size : 2
    max_size : 6
    desired_size : 2
    cpu_threshold: 60
    instance_cooldown: 60
  }
}

variable "root_block_device" {
  type = list(map(string))
  default = [{
    volume_size : 50
    volume_type : "gp2"
    delete_on_termination : true
  }]
}

variable "private_subnets" {
  type        = list
  description = "The private subnets where the EC2 instances will be created"
}

##### Keypair required values

variable "overwrite_ssm_parameter" {
  type        = string
  default     = "true"
  description = "Whether to overwrite an existing SSM parameter"
}

variable "tls_algorithm" {
  type        = string
  default     = "RSA"
  description = "SSH key algorithm to use. Currently-supported values are 'RSA' and 'ECDSA'"
}

variable "rsa_bits" {
  type        = string
  default     = 4096
  description = "When ssh_key_algorithm is 'RSA', the size of the generated RSA key in bits"
}

variable "ssh_public_key_path" {
  type        = string
  default     = "../keys"
  description = "path to the keys location"
}

variable "public_key_extension" {
  type        = string
  default     = ".pub"
  description = "Extention of the Public Key needed to add the KeyPair"
}

variable "private_key_extension" {
  type        = string
  default     = ".pem"
  description = "Extension of the Private Key needed for SSH"
}

variable "chmod_command" {
  type        = string
  default     = "chmod 600 %v"
  description = "Template of the command executed on the private key file"
}

variable "save_local_key" {
  type        = bool
  description = "Enable the local save of the keypair"
  default     = false
}

##### ECS Configuration

variable "container_insights" {
  type = bool
  description = "Enable container insights"
  default = false
}