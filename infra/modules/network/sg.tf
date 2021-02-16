resource "aws_security_group" "default" {
  vpc_id = aws_vpc.vpc.id
  name = join("-", [var.env_name, "default", "sg"])
  description = "Default security group. Used to access AWS resources"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = [join("",slice(split("",var.env_name),0,1)) == "d" || join("",slice(split("",var.env_name),0,1)) == "t" ? aws_vpc.vpc.cidr_block : "169.254.0.1/32"]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "TCP"
    cidr_blocks = [join("",slice(split("",var.env_name),0,1)) == "d" || join("",slice(split("",var.env_name),0,1)) == "t" ? aws_vpc.vpc.cidr_block : "169.254.0.1/32"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}