
provider "aws" {
  version = "~> 3.0"
  region  = var.aws_region
}

module "network" {
  vpc_parameter = var.vpc_parameter
  source        = "./network"
}

module "security" {
  vpc_parameter = var.vpc_parameter
  source        = "./security"
}

module "policy" {
  source        = "./policy"
}

module "lambda" {
  private_subnet = module.network.private_subnet
  private_sg     = module.security.private_sg
  lambda_role    = module.policy.lambda_role
  source         = "./lambda"
}

