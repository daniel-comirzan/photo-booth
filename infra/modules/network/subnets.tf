data "aws_availability_zones" "available" {}

locals {
  number_of_subnets = var.subnet_count == "0" ?  length(data.aws_availability_zones.available.names) : var.subnet_count
  private_cidr      = var.enable_public_subnet == "true" ? local.number_of_subnets : (local.number_of_subnets - 1)
}

resource "aws_subnet" "private" {
  count                   = local.number_of_subnets
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(var.vpc_cidr, local.private_cidr, count.index)
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.vpc.id

  tags = merge(
    var.common_tags,
    map("Name", join("-", [var.env_name, "pri", count.index + 1]))
  )
}

resource "aws_subnet" "public" {
  count                   = var.enable_public_subnet == "true" ? local.number_of_subnets : 0
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(var.vpc_cidr, local.number_of_subnets, count.index + local.number_of_subnets)
  ipv6_cidr_block         = cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.vpc.id

  tags = merge(
    var.common_tags,
    map("Name", join("-", [var.env_name, "pub", count.index + 1]))
  )
}

resource "aws_route_table" "private_route" {
  count  = local.number_of_subnets
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    var.common_tags,
    map("Name", join("-", [var.env_name, "pri", count.index + 1]))
  )
}

resource "aws_route" "private_2_public" {
  count                  = var.enable_public_subnet  ? local.number_of_subnets : 0
  route_table_id         = element(aws_route_table.private_route.*.id, count.index)
  nat_gateway_id         = element(aws_nat_gateway.nat-gw.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "public_route" {
  count  = var.enable_public_subnet  ? local.number_of_subnets : 0
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    var.common_tags,
    map("Name", join("-", [var.env_name, "pub", count.index + 1]))
  )
}

resource "aws_route" "public_2_internet_ipv4" {
  count                  = var.enable_public_subnet  ? local.number_of_subnets : 0
  route_table_id         = element(aws_route_table.public_route.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default[0].id
}

resource "aws_route" "public_2_internet_ipv6" {
  count                       = var.enable_public_subnet  ? local.number_of_subnets : 0
  route_table_id              = element(aws_route_table.public_route.*.id, count.index)
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.default[0].id
}

resource "aws_route_table_association" "private" {
  count          = local.number_of_subnets
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private_route.*.id, count.index)
}

resource "aws_route_table_association" "public" {
  count          = var.enable_public_subnet == "true" ? local.number_of_subnets : 0
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = element(aws_route_table.public_route.*.id, count.index)
}
