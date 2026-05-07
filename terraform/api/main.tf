data "aws_caller_identity" "current" {}

resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.prefix}-api"
  description = "API Gateway for the Shortly service"

  // helps with downtime, basically terraform might destroy an API and then recreate it, but this forces it to first create it and then delete it.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    module.endpoint_hash,
    #TODO: add other endpoints here
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode([
      module.endpoint_hash.resource_ids,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "prod"

  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn

    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}

module "endpoint_hash" {
  source = "./endpoint-hash"

  rest_api_config = {
    api_id           = aws_api_gateway_rest_api.api.id
    root_resource_id = aws_api_gateway_rest_api.api.root_resource_id
    execution_arn    = aws_api_gateway_rest_api.api.execution_arn
  }

  prefix                    = var.prefix
  table_arn                 = var.table_arn
  hash_length               = var.hash_length
  max_hash_attempts         = var.max_hash_attempts
  private_subnets_ids       = var.private_subnets_ids
  lambda_kms_key_arn        = aws_kms_key.lambda_env.arn
  dynamodb_kms_key_arn      = var.dynamodb_kms_key_arn
  vpc_id                    = var.vpc_id
  max_concurrent_executions = local.max_concurrent_executions

  code_signing_config = {
    code_signing_bucket_id = module.code_signing_bucket.bucket_id
    signing_profile_arn    = aws_signer_signing_profile.this.arn
    signing_config_arn     = aws_lambda_code_signing_config.this.arn
  }
}

resource "aws_kms_key" "lambda_env" {
  description             = "KMS key for Lambda environment variables"
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

resource "aws_kms_alias" "lambda_env" {
  name          = "alias/${var.prefix}-lambda-env"
  target_key_id = aws_kms_key.lambda_env.key_id
}

resource "aws_api_gateway_method_settings" "api_settings" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.api_stage.stage_name
  method_path = "*/*"

  settings {
    logging_level      = "INFO"
    metrics_enabled    = true
    data_trace_enabled = false
  }
}

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/api-gateway/${var.prefix}-api"
  retention_in_days = 365
}


locals {
  max_concurrent_executions = 300
}