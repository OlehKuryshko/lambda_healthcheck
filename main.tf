module "security" {
  vpc_parameter = aws_vpc.main.id
  source        = "./security"
  owner         = var.owner
  depends_on = [module.policy]
}
module "policy" {
  source        = "./policy"
}
module "dynamodb" {
  source        = "./dynamodb"
}
module "lambda" {
  # private_subnet = aws_subnet.private.id
  # private_sg     = module.security.private_sg
  lambda_role    = module.policy.lambda_role
  source         = "./lambda"
  depends_on = [aws_nat_gateway.main-natgw, module.dynamodb, module.policy]
}