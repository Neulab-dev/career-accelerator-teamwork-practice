resource "aws_lambda_function" "hash_lambda" {
  function_name = "${var.prefix}-hash"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda.handler"
  runtime       = "nodejs24.x"
  # This prevents the Lambda from scaling infinitely
  reserved_concurrent_executions = var.max_concurrent_executions

  s3_bucket = aws_signer_signing_job.this.signed_object[0].s3[0].bucket
  s3_key    = aws_signer_signing_job.this.signed_object[0].s3[0].key

  code_signing_config_arn = var.code_signing_config.signing_profile_arn

  kms_key_arn = var.lambda_kms_key_arn
  # for X-Ray
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

resource "aws_s3_object" "unsigned" {
  bucket = var.code_signing_config.code_signing_bucket_id
  key    = "unsigned/${var.prefix}-hash-lambda/lambda.zip"
  source = data.archive_file.lambda_zip.output_path
}

resource "aws_signer_signing_job" "this" {
  profile_name = reverse(split("/", var.code_signing_config.signing_profile_arn))[0]

  source {
    s3 {
      bucket  = var.code_signing_config.code_signing_bucket_id
      key     = aws_s3_object.unsigned.id
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


resource "aws_security_group" "hash_lambda_sg" {
  name        = "${var.prefix}-hash-lambda"
  description = "Security group for the hash Lambda function"
  vpc_id      = var.vpc_id
}