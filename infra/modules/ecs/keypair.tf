locals {
  public_key_filename = format(
    "%s/%s%s",
    var.ssh_public_key_path,
    var.env_name,
    var.public_key_extension,
  )
  private_key_filename = format(
    "%s/%s%s",
    var.ssh_public_key_path,
    var.env_name,
    var.private_key_extension,
  )
}

resource "tls_private_key" "tls_aws_keypair" {
  algorithm = var.tls_algorithm
  rsa_bits  = var.rsa_bits
}

resource "aws_key_pair" "aws_keypair" {
  key_name   = var.env_name
  public_key = tls_private_key.tls_aws_keypair.public_key_openssh
  depends_on = [tls_private_key.tls_aws_keypair]
}

resource "aws_ssm_parameter" "private_rsa_key" {
  name        = "/${var.env_name}/keypair"
  description = "TLS Private Key"
  type        = "SecureString"
  value       = join("", tls_private_key.tls_aws_keypair.*.private_key_pem)
  overwrite   = var.overwrite_ssm_parameter
  depends_on  = [tls_private_key.tls_aws_keypair]
}

resource "aws_ssm_parameter" "public_rsa_key" {
  name        = "/${var.env_name}/pubkey"
  description = "TLS Public Key (OpenSSH - ${var.tls_algorithm})"
  type        = "String"
  value       = join("", tls_private_key.tls_aws_keypair.*.public_key_openssh)
  overwrite   = var.overwrite_ssm_parameter
  depends_on  = [tls_private_key.tls_aws_keypair]
}

resource "local_file" "private_key_pem" {
  count      = var.save_local_key ? 1 : 0
  depends_on = [tls_private_key.tls_aws_keypair]
  content    = tls_private_key.tls_aws_keypair.private_key_pem
  filename   = local.private_key_filename
}

resource "null_resource" "chmod" {
  depends_on = [local_file.private_key_pem]

  triggers = {
    local_file_private_key_pem = "local_file.private_key_pem"
  }

  provisioner "local-exec" {
    command = format(var.chmod_command, local.private_key_filename)
  }
}

