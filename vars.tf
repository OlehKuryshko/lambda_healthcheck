variable "aws_region" {
  default = "us-east-1"
}

variable "aws_access_key_id" {
  default = ""
}

variable "aws_secret_access_key" {
  default = ""
}

variable "vpc_parameter" {
  default = {
    vpc_id            = "vpc-0703617471eb7e67f"
    igw_id            = "igw-021b947aa9dd33038"
    vpc_subnet        = "172.30.0.0/16"
    public_subnet     = "172.30.250.0/24"
    private_subnet    = "172.30.11.0/24"
    availability_zone = "us-east-1a"
  }
}
