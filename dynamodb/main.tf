resource "aws_dynamodb_table" "milan-lambda-table" {
  name           = "milan-lambda-table"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "Address"

  attribute {
    name = "Address"
    type = "S"
  }

  #   attribute {
  #     name = "TimesFailed"
  #     type = "N"
  #   }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = false
  }

  tags = {
    Name  = "milan-lambda-table"
    Owner = "mmel2"
  }
}
