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

  api_id               = ""
  endpoint_name        = ""
  execution_arn        = ""
  http_method          = ""
  lambda_function_name = ""
  lambda_invoke_arn    = ""
  prefix               = ""
  resource_id          = ""
  table_arn            = ""
  table_name           = ""
}