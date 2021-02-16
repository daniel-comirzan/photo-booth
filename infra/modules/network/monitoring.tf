data "aws_region" "current" {}

resource "aws_sns_topic" "sns_topic" {
  count = var.enable_sns  ? 1 : 0
  name  = join("-", [var.env_name, "sns"])

  tags = var.common_tags

}

resource "null_resource" "sns_subscribe" {
  depends_on = [aws_sns_topic.sns_topic]

  triggers = {
    sns_topic_arn = aws_sns_topic.sns_topic[count.index].arn
  }

  count = var.enable_sns ? length(var.sns_email_subscribers) : 0

  provisioner "local-exec" {
    command = "aws sns subscribe --topic-arn ${aws_sns_topic.sns_topic[count.index].arn} --protocol email --notification-endpoint ${element(var.sns_email_subscribers, count.index)}"
  }
}

resource "aws_cloudtrail" "cloudtrail" {
  count                      = var.enable_cloudtrail == "true" ? 1 : 0
  name                       = join("-", [var.env_name, "cloudtrail"])
  s3_bucket_name             = aws_s3_bucket.cloudtrail[count.index].id
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail-default-logging[count.index].arn
  cloud_watch_logs_group_arn = aws_cloudwatch_log_group.cloudtrail-default[count.index].arn

  include_global_service_events = true
  is_multi_region_trail         = false
  enable_log_file_validation    = true
  enable_logging                = true

  tags = var.common_tags
}

data "aws_iam_policy_document" "cloudtrail" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["cloudtrail.amazonaws.com"]
      type = "Service"
    }
    actions = ["s3:GetBucketAcl"]
    resources = [join("/",[var.logs_bucket])]
  }
}

resource "aws_s3_bucket" "cloudtrail" {
  count               = var.enable_cloudtrail == "true" ? 1 : 0
  bucket              = "${var.env_name}-cloudtrail-${var.account_id}-${data.aws_region.current.name}"
  acl                 = "private"
  acceleration_status = "Suspended"
  request_payer       = "BucketOwner"
  force_destroy       = true

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${var.env_name}-cloudtrail-${var.account_id}-${data.aws_region.current.name}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${var.env_name}-cloudtrail-${var.account_id}-${data.aws_region.current.name}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY

  versioning {
    enabled = true
  }

  tags = var.common_tags
}

# cloudwatch logs role for cloudtrail
resource "aws_iam_role" "cloudtrail-default-logging" {
  count = var.enable_cloudtrail == "true" ? 1 : 0
  name  = "cloudtrail-${var.account_id}-${data.aws_region.current.name}"

  tags = var.common_tags

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
  EOF
}

resource "aws_iam_role_policy" "cloudtrail-default-logging" {
  count = var.enable_cloudtrail ? 1 : 0
  name  = "${var.env_name}-cloudtrail-${var.account_id}-${data.aws_region.current.name}"
  role  = aws_iam_role.cloudtrail-default-logging[count.index].id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailCreateLogStream20141101",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream"
            ],
            "Resource": [
                "arn:aws:logs:${data.aws_region.current.name}:${var.account_id}:log-group:CloudTrail/${data.aws_region.current.name}:log-stream:${var.account_id}_CloudTrail_${data.aws_region.current.name}*"
            ]
        },
        {
            "Sid": "AWSCloudTrailPutLogEvents20141101",
            "Effect": "Allow",
            "Action": [
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:${data.aws_region.current.name}:${var.account_id}:log-group:CloudTrail/${data.aws_region.current.name}:log-stream:${var.account_id}_CloudTrail_${data.aws_region.current.name}*"
            ]
        }
    ]
}
  EOF
}

resource "aws_cloudwatch_log_group" "cloudtrail-default" {
  count             = var.enable_cloudtrail == "true" ? 1 : 0
  name              = "CloudTrail/${data.aws_region.current.name}"
  retention_in_days = 7
  tags = var.common_tags
}
