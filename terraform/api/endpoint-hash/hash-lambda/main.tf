data "aws_region" "current" {}
data "aws_prefix_list" "dynamodb" {
  name = "com.amazonaws.${data.aws_region.current.region}.dynamodb"
}

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

resource "aws_iam_role_policy" "kms_policy" {
  name = "${var.prefix}-lambda-kms-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ]
      Resource = var.dynamodb_kms_key_arn
    }]
  })
}
# basic logs
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

// For X-Ray permissions
resource "aws_iam_role_policy_attachment" "lambda_xray" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# the Lambda execution role needs EC2 network interface permissions. Otherwise it cannot create the vpc endpoint.
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
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

resource "aws_kms_key" "lambda" {
  description             = "KMS key for encrypting ${var.prefix} hash Lambda environment variables"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.prefix}-hash-lambda-kms"
  }
}

resource "aws_kms_alias" "lambda" {
  name          = "alias/${var.prefix}-hash-lambda"
  target_key_id = aws_kms_key.lambda.key_id
}

# Lambda
resource "aws_lambda_function" "hash_lambda" {
  function_name = "${var.prefix}-hash"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda.handler"
  runtime       = "nodejs24.x"
  /*
  This prevents the Lambda from scaling infinitely.
  commented out reserved_concurrent_executions because the current AWS account has a Lambda concurrency quota of 10,
  and AWS requires 10 unreserved executions to remain available. Because of that, this environment cannot reserve concurrency for the function.
  The setting is still useful as a production safety limit, but it cannot be enabled with the current account quota.
  */

  # reserved_concurrent_executions = 10
  timeout          = 10
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  kms_key_arn = aws_kms_key.lambda.arn
  // for X-Ray
  tracing_config {
    mode = "Active"
  }
  vpc_config {
    // We are adding this for security reasons - https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/ensure-that-aws-lambda-function-is-configured-inside-a-vpc-1
    subnet_ids         = var.private_subnets_ids
    security_group_ids = [aws_security_group.hash_lambda_sg.id]
  }

  environment {
    variables = {
      TABLE_NAME        = split("/", var.table_arn)[1]
      HASH_LENGTH       = tostring(var.hash_length)
      MAX_HASH_ATTEMPTS = tostring(var.max_hash_attempts)
    }
  }
}
// Allow only HTTPS outbound traffic to DynamoDB. GetItem and PutItem calls go over HTTPS, port 443.
resource "aws_security_group" "hash_lambda_sg" {
  name        = "${var.prefix}-hash-lambda"
  description = "Security group for the hash Lambda function"
  vpc_id      = var.vpc_id

  egress {
    description     = "Allow HTTPS traffic to DynamoDB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_prefix_list.dynamodb.id]
  }
}