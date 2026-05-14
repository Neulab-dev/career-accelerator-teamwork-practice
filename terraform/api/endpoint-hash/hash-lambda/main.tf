data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_prefix_list" "dynamodb" {
  name = "com.amazonaws.${data.aws_region.current.region}.dynamodb"
}

resource "aws_kms_key" "lambda" {
  description             = "KMS key for encrypting ${var.prefix} hash Lambda environment variables"
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
  timeout       = "7"
  # This prevents the Lambda from scaling infinitely
  reserved_concurrent_executions = var.max_concurrent_executions

  s3_bucket = aws_signer_signing_job.signing_job.signed_object[0].s3[0].bucket
  s3_key    = aws_signer_signing_job.signing_job.signed_object[0].s3[0].key

  code_signing_config_arn = var.code_signing_config.signing_config_arn

  kms_key_arn = aws_kms_key.lambda.arn

  tracing_config {
    mode = "Active"
  }

  vpc_config {
    # We are adding this for security reasons - https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/ensure-that-aws-lambda-function-is-configured-inside-a-vpc-1
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

# ZIP lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-code"
  output_path = "${path.module}/lambda.zip"
}

locals {
  unsigned_object_key = "unsigned/${var.prefix}-hash-lambda/lambda.zip"
}

resource "aws_s3_object" "unsigned" {
  bucket = var.code_signing_config.code_signing_bucket_id
  key    = local.unsigned_object_key
  source = data.archive_file.lambda_zip.output_path
}

resource "aws_signer_signing_job" "signing_job" {
  profile_name = reverse(split("/", var.code_signing_config.signing_profile_arn))[0]

  source {
    s3 {
      bucket  = var.code_signing_config.code_signing_bucket_id
      key     = local.unsigned_object_key
      version = aws_s3_object.unsigned.version_id
    }
  }

  destination {
    s3 {
      bucket = var.code_signing_config.code_signing_bucket_id
      prefix = "signed/"
    }
  }

  ignore_signing_job_failure = true
}


# Allow only HTTPS outbound traffic to DynamoDB. GetItem and PutItem calls go over HTTPS, port 443.
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
