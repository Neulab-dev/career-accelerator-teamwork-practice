# DynamoDB
resource "aws_dynamodb_table" "shortly" {
  name         = "${var.prefix}-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "hash"

  attribute {
    name = "hash"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
}