terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    archive = {
      source = "hashicorp/archive"
    }
  }
}

variable "prefix" {
  type = string
}

variable "table_name" {
  type = string
}

variable "hash_length" {
  type    = number
  default = 6
}

variable "max_hash_attempts" {
  type    = number
  default = 10
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#zipvane
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda.js"
  output_path = "${path.module}/lambda.zip"
}

#IAM Role
resource "aws_iam_role" "lambda_role" {
  name = "${var.prefix}-hash-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}
#basic logging
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
#least privilige
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
      Resource = "arn:aws:dynamodb:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:table/${var.table_name}"
    }]
  })
}

resource "aws_lambda_function" "hash_lambda" {
  function_name = "${var.prefix}-hash-lambda"
  role          = aws_iam_role.lambda_role.arn

  runtime = "nodejs24.x"
  handler = "lambda.handler"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout     = 10
  memory_size = 128

  environment {
    variables = {
      TABLE_NAME        = var.table_name
      HASH_LENGTH       = tostring(var.hash_length)
      MAX_HASH_ATTEMPTS = tostring(var.max_hash_attempts)
    }
  }
}

output "lambda_name" {
  value = aws_lambda_function.hash_lambda.function_name
}

output "lambda_arn" {
  value = aws_lambda_function.hash_lambda.arn
}

output "lambda_invoke_arn" {
  value = aws_lambda_function.hash_lambda.invoke_arn
}