variable "vpc_parameter" {
  default = ""
}

# public network settings
resource "aws_subnet" "public" {
  vpc_id                  = var.vpc_parameter.vpc_id
  cidr_block              = var.vpc_parameter.public_subnet
  availability_zone       = var.vpc_parameter.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name  = "lambda-public-subnet"
    Owner = "mmel2"
  }
}

resource "aws_route_table" "public" {
  vpc_id = var.vpc_parameter.vpc_id

  route {
    gateway_id = var.vpc_parameter.igw_id
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name  = "route-table-public-subnet"
    Owner = "mmel2"
  }
}

resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public.id
}

# private network settings
resource "aws_subnet" "private" {
  vpc_id                  = var.vpc_parameter.vpc_id
  cidr_block              = var.vpc_parameter.private_subnet
  availability_zone       = var.vpc_parameter.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name  = "lambda-private-subnet"
    Owner = "mmel2"
  }
}

resource "aws_eip" "nat_eip" {
  vpc = true

  tags = {
    Name  = "nat-eip"
    Owner = "mmel2"
  }
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name  = "lambda-nat"
    Owner = "mmel2"
  }
}

resource "aws_route_table" "private" {
  vpc_id = var.vpc_parameter.vpc_id

  route {
    nat_gateway_id = aws_nat_gateway.natgw.id
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name  = "route-table-private-subnet"
    Owner = "mmel2"
  }
}

resource "aws_route_table_association" "private" {
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private.id
}
