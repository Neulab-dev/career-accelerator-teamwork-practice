# DynamoDB

data "aws_caller_identity" "current" {}
resource "aws_dynamodb_table" "shortly" {
  name         = "${var.prefix}-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "hash"

  attribute {
    name = "hash"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }
  /*
      KMS:
          AWS default encryption exists
          but Checkov wants a custom KMS key not the default AWS one
   */
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }
}
// KMS
resource "aws_kms_key" "dynamodb" {
  description             = "KMS key for Shortly DynamoDB table"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      }
    ]
  })
}


resource "aws_kms_alias" "dynamodb" {
  name          = "alias/${aws_dynamodb_table.shortly.name}"
  target_key_id = aws_kms_key.dynamodb.key_id
}