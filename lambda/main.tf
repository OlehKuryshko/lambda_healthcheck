variable "private_subnet" {
  default = ""
}
variable "private_sg" {
  default = ""
}

variable "lambda_role" {
  default = ""
}

data "archive_file" "arch" {
  type        = "zip"
  source_file = "function.py"
  output_path = "function.zip"
}

resource "aws_lambda_function" "healthcheck" {
  filename         = "function.zip"
  function_name    = "oleh-test"
  role             = var.lambda_role
  handler          = "function.lambda_handler"
  source_code_hash = data.archive_file.arch.output_base64sha256
  runtime          = "python3.7"
  timeout          = "30"
  memory_size      = 256
  
  vpc_config {
    subnet_ids         = [var.private_subnet]
    security_group_ids = [var.private_sg]
  }

  tags = {
    name  = "oleh-healthcheck-lambda"
    Owner = "okury"
  }
}

resource "aws_cloudwatch_event_rule" "every_five_minutes" {
  name                = "every-five-minutes"
  description         = "Fires every five minutes"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "checkhealth_every_five_minutes" {
  rule      = aws_cloudwatch_event_rule.every_five_minutes.name
  target_id = "check_foo"
  arn       = aws_lambda_function.healthcheck.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_healthcheck" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.healthcheck.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_five_minutes.arn
}
