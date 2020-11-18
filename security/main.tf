variable "vpc_parameter" {
  default = ""
}
variable "owner" {
  default = ""
}

resource "aws_security_group" "public" {
  vpc_id = var.vpc_parameter

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "lambda-public-sg"
    Owner = var.owner
  }
}

resource "aws_security_group" "private" {
  vpc_id = var.vpc_parameter

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.public.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags =  {
    Name  = "lambda-private-sg"
    Owner = var.owner
  }
}