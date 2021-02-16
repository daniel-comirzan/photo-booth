resource "aws_s3_bucket" "config_bucket" {
  bucket = join("-",[var.env_name,"config"])
  acl    = "private"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket" "logs_bucket" {
  bucket = join("-",[var.env_name,"logs"])
  acl    = "private"

  policy = data.aws_iam_policy_document.default.json

  versioning {
    enabled = true
  }
}