resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "eip-${var.namespace}-nat"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.public_subnet_id

  tags = {
    Name = "nat-${var.namespace}"
  }
}