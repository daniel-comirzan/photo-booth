# Create a NAT gateway with an EIP for each private subnet to get internet connectivity
resource "aws_eip" "nat-eip" {
  count = var.enable_public_subnet ? local.number_of_subnets : 0
  vpc   = true
  tags = merge(
    var.common_tags,
    map("Name", join("-", [var.env_name, count.index + 1]))
  )
}

resource "aws_nat_gateway" "nat-gw" {
  count         = var.enable_public_subnet ? local.number_of_subnets : 0
  allocation_id = element(aws_eip.nat-eip.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)

  depends_on = [
    aws_internet_gateway.default,
  ]
  tags = merge(
    var.common_tags,
    map("Name", join("-", [var.env_name, count.index + 1]))
  )
}
