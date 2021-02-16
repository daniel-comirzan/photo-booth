resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  //instance_tenancy = ""
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true

  tags = var.common_tags
}

resource "aws_internet_gateway" "default" {
  count  = var.enable_public_subnet == "true" ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    map("Name", join("-", [var.env_name, "igw"])),
    var.common_tags
  )

}

resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.vpc.default_network_acl_id

  subnet_ids = flatten([
    aws_subnet.public.*.id,
    aws_subnet.private.*.id,
  ])

  lifecycle {
    ignore_changes = [subnet_ids, ingress, egress]
  }

  tags = var.common_tags
}

resource "aws_network_acl_rule" "ingress_100" {
  network_acl_id = aws_default_network_acl.default.id
  protocol       = "tcp"
  egress         = false
  rule_action    = "allow"
  rule_number    = 100
  cidr_block     = "0.0.0.0/0"
  from_port      = 1
  to_port        = 65535
}

resource "aws_network_acl_rule" "ingress_101" {
  network_acl_id = aws_default_network_acl.default.id
  protocol       = "udp"
  egress         = false
  rule_action    = "allow"
  rule_number    = 101
  cidr_block     = "0.0.0.0/0"
  from_port      = 1
  to_port        = 65535
}

resource "aws_network_acl_rule" "ingress_102" {
  network_acl_id = aws_default_network_acl.default.id
  protocol       = "icmp"
  egress         = false
  rule_action    = "allow"
  rule_number    = 102
  cidr_block     = var.vpc_cidr
  from_port      = 0
  to_port        = 0
  icmp_code      = 0
  icmp_type      = 8
}

resource "aws_network_acl_rule" "ingress_103" {
  network_acl_id  = aws_default_network_acl.default.id
  protocol        = "tcp"
  egress          = false
  rule_action     = "allow"
  rule_number     = 103
  ipv6_cidr_block = "::/0"
  from_port       = 443
  to_port         = 443
}

resource "aws_network_acl_rule" "ingress_104" {
  network_acl_id = aws_default_network_acl.default.id
  protocol       = "ipv4"
  egress         = false
  rule_action    = "allow"
  rule_number    = 104
  cidr_block     = "0.0.0.0/0"

}

resource "aws_network_acl_rule" "egress_100" {
  network_acl_id = aws_default_network_acl.default.id
  protocol       = "tcp"
  egress         = true
  rule_action    = "allow"
  rule_number    = 100
  cidr_block     = "0.0.0.0/0"
  from_port      = 1
  to_port        = 65535
}

resource "aws_network_acl_rule" "egress_101" {
  network_acl_id = aws_default_network_acl.default.id
  protocol       = "udp"
  egress         = true
  rule_action    = "allow"
  rule_number    = 101
  cidr_block     = "0.0.0.0/0"
  from_port      = 1
  to_port        = 65535
}

resource "aws_network_acl_rule" "egress_102" {
  network_acl_id = aws_default_network_acl.default.id
  protocol       = "icmp"
  egress         = true
  rule_action    = "allow"
  rule_number    = 102
  cidr_block     = var.vpc_cidr
  from_port      = 0
  to_port        = 0
  icmp_type      = 0
  icmp_code      = 0
}

resource "aws_network_acl_rule" "egress_103" {
  network_acl_id  = aws_default_network_acl.default.id
  protocol        = "tcp"
  egress          = true
  rule_action     = "allow"
  rule_number     = 103
  ipv6_cidr_block = "::/0"
  from_port       = 1
  to_port         = 65535
}

resource "aws_network_acl_rule" "egress_104" {
  network_acl_id = aws_default_network_acl.default.id
  protocol       = "ipv4"
  egress         = true
  rule_action    = "allow"
  rule_number    = 104
  cidr_block     = "0.0.0.0/0"
  from_port      = 1
  to_port        = 65535
}

data "aws_iam_policy_document" "vpc_endpoint" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["*"]
  }
}

resource "aws_vpc_endpoint" "vpc_endpoint" {
  for_each     = toset(["s3", "dynamodb"])
  vpc_id       = aws_vpc.vpc.id
  service_name = join(".", ["com.amazonaws", var.region, each.key])

  route_table_ids = flatten([
    aws_route_table.private_route.*.id,
  ])

  policy = data.aws_iam_policy_document.vpc_endpoint.json
}


