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
  source_file = "handler.py"
  output_path = "handler-arch.zip"
}

resource "aws_lambda_function" "healthcheck" {
  filename         = "handler-arch.zip"
  function_name    = "healthcheck_lambda"
  role             = var.lambda_role
  handler          = "handler.healthcheck"
  source_code_hash = data.archive_file.arch.output_base64sha256
  runtime          = "python3.7"
  vpc_config {
    subnet_ids         = [var.private_subnet]
    security_group_ids = [var.private_sg]
  }

  tags = {
    name  = "milan-healthcheck-lambda"
    Owner = "mmel2"
  }
}

resource "aws_cloudwatch_event_rule" "every_five_minutes" {
  name                = "every-five-minutes"
  description         = "Fires every five minutes"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "checkhealth_every_five_minutes" {
  rule      = aws_cloudwatch_event_rule.every_five_minutes.name
  target_id = "check_fun"
  arn       = aws_lambda_function.healthcheck.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_healthcheck" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.healthcheck.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_five_minutes.arn
}
