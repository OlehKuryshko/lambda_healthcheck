resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  # enable_dns_hostnames = true
  # enable_dns_support   = true
  tags = {
    Name = "main"
    owner = var.owner
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
    owner = var.owner
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs
  availability_zone = var.availability_zone
  tags = {
    Name = "private-subnet"
    owner = var.owner
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "internet-gateway"
    owner = var.owner
  }
}
resource "aws_eip" "nat-eip" {
  vpc = true
  tags = {
    owner = var.owner
  }
}

resource "aws_nat_gateway" "main-natgw" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "main-nat"
    owner = var.owner
  }
}

resource "aws_route_table" "main-public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = var.my_cidr
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "main-public"
    owner = var.owner
  }
}

resource "aws_route_table" "main-private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = var.my_cidr
    gateway_id = aws_nat_gateway.main-natgw.id
  }
  tags = {
    Name = "main-private"
    owner = var.owner
  }
}
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.main-public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.main-private.id
}