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
}

module "endpoint_hash" {
  source = "./endpoint-hash"

  rest_api_config = {
    api_id           = aws_api_gateway_rest_api.api.id
    root_resource_id = aws_api_gateway_rest_api.api.root_resource_id
    execution_arn    = aws_api_gateway_rest_api.api.execution_arn
  }

  prefix              = var.prefix
  table_arn           = var.table_arn
  hash_length         = var.hash_length
  max_hash_attempts   = var.max_hash_attempts
  private_subnets_ids = var.private_subnets_ids
}

resource "aws_kms_key" "lambda_env" {
  description             = "KMS key for Lambda environment variables"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "lambda_env" {
  name          = "alias/${var.prefix}-lambda-env"
  target_key_id = aws_kms_key.lambda_env.key_id
}