# ZIP lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-code"
  output_path = "${path.module}/lambda.zip"
}

# IAM role
resource "aws_iam_role" "lambda_role" {
  name = "${var.prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# basic logs
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# policy
resource "aws_iam_role_policy" "dynamodb_policy" {
  name = "${var.prefix}-dynamodb-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem"
      ]
      Resource = var.table_arn
    }]
  })
}

# Lambda
resource "aws_lambda_function" "hash_lambda" {
  function_name = "${var.prefix}-hash"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda.handler"
  runtime       = "nodejs24.x"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  environment {
    variables = {
      TABLE_NAME   = split("/", var.table_arn)[1]
      HASH_LENGTH  = tostring(var.hash_length)
      MAX_HASH_ATTEMPTS = tostring(var.max_hash_attempts)
    }
  }
}