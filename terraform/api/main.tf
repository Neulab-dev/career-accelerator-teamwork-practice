resource "aws_lambda_permission" "allow_apigateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.hash_lambda.lambda_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.execution_arn}/*/POST/hash"
}

resource "aws_api_gateway_integration" "hash_integration" {
  rest_api_id             = var.api_id
  resource_id             = var.resource_id
  http_method             = "POST"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.hash_lambda.lambda_invoke_arn
}

module "hash_lambda" {
  source = "./hash-lambda"
}
