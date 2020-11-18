resource "aws_dynamodb_table" "oleh-lambda-table" {
  name           = "oleh-lambda-table"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "Address"

  attribute {
    name = "Address"
    type = "S"
  }

    # attribute {
    #   name = "TimesFailed"
    #   type = "N"
    # }

  # ttl {
  #   attribute_name = "TimeToExist"
  #   enabled        = false
  # }
  ttl {
    attribute_name = "UpdateTime"
    enabled        = true
  }

  tags = {
    Name  = "oleh-lambda-table"
    Owner = "okury"
  }
}