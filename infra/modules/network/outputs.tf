output "vpc" {
  value = aws_vpc.vpc
}

output "subnets_public" {
  value = aws_subnet.public
}

output "subnets_private" {
  value = aws_subnet.private
}

output "availability_zone" {
  value = [aws_subnet.private.*.availability_zone]
}

output "private_subnets" {
  value = [aws_subnet.private.*.id]
}

output "private_subnet_cidr" {
  value = [aws_subnet.private.*.cidr_block]
}

output "public_subnets" {
  value = [aws_subnet.public.*.id]
}

output "public_subnet_cidr" {
  value = [aws_subnet.public.*.cidr_block]
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.vpc.cidr_block
}

output "security_group_ott_management_id" {
  value = aws_security_group.default.*.id
}

output "nat-gw" {
  value = [aws_nat_gateway.nat-gw.*.public_ip]
}

output "sns_topic_arn" {
  value = aws_sns_topic.sns_topic.*.arn
}
