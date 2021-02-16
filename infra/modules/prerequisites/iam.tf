data "aws_elb_service_account" "elb_service_account" {}

data "aws_iam_policy_document" "default" {
  statement {
    sid = "ELBLogsPermissions"

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.elb_service_account.arn]
    }

    effect = "Allow"

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::${var.env_name}-logs/*",
    ]
  }

  statement {
    sid = "CWLogsPermissionsACL"
    effect = "Allow"
    principals {
      identifiers = [join(".",["logs", var.region, "amazonaws", "com"])]
      type = "Service"
    }
    actions = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::${var.env_name}-logs"]
  }

  statement {
    sid = "CWLogsPermissionsData"
    effect = "Allow"
    principals {
      identifiers = [join(".",["logs", var.region, "amazonaws", "com"])]
      type = "Service"
    }
    actions = ["s3:PutObject"]
    resources = [join("/", ["arn:aws:s3:::${var.env_name}-logs", "*"])]
    condition {
      test = "StringEquals"
      values = ["bucket-owner-full-control"]
      variable = "s3:x-amz-acl"
    }
  }
}