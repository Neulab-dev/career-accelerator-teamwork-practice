resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.prefix}-api"
  description = "API Gateway for the Shortly service"
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

  prefix            = var.prefix
  table_arn         = var.table_arn
  hash_length       = var.hash_length
  max_hash_attempts = var.max_hash_attempts
}

output "api_invoke_url" {
  value = "${aws_api_gateway_stage.api_stage.invoke_url}/hash"
}
