resource "aws_api_gateway_resource" "hash_resource" {
  rest_api_id = var.rest_api_config.api_id
  parent_id   = var.rest_api_config.root_resource_id
  path_part   = "hash"
}

resource "aws_api_gateway_method" "hash_method" {
  rest_api_id   = var.rest_api_config.api_id
  resource_id   = aws_api_gateway_resource.hash_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_lambda_permission" "allow_apigateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.hash_lambda.lambda_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.rest_api_config.execution_arn}/*/POST/hash"
}

resource "aws_api_gateway_integration" "hash_integration" {
  rest_api_id             = var.rest_api_config.api_id
  resource_id             = aws_api_gateway_resource.hash_resource.id
  http_method             = "POST"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.hash_lambda.invoke_lambda_arn

  depends_on = [aws_api_gateway_method.hash_method]
}

# TODO you can get table name from table arn
module "hash_lambda" {
  source = "./hash-lambda"

  prefix            = var.prefix
  table_arn         = var.table_arn
  max_hash_attempts = var.max_hash_attempts
  hash_length       = var.hash_length
}