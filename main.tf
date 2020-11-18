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



















# data "archive_file" "arch" {
#   type        = "zip"
#   source_file = "handler.py"
#   output_path = "handler.zip"
# }

# resource "aws_lambda_function" "test_lambda" {
#   filename         = "handler.zip"
#   function_name    = "test_lambda"
#   role             = module.policy.lambda_role
#   handler          = "handler.lambda_handler"
#   source_code_hash = "${data.archive_file.arch.output_base64sha256}"
#   runtime          = "python3.7"
#   timeout          = "30"
#   memory_size      = 256
#   vpc_config {
#     subnet_ids         = [aws_subnet.private.id]
#     security_group_ids = [module.web.id]
#   }
# }

