resource "aws_api_gateway_method" "endpoint_method" {
  rest_api_id   = var.api_id
  resource_id   = var.resource_id
  http_method   = var.http_method
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = var.api_id
  resource_id = var.resource_id
  http_method = aws_api_gateway_method.endpoint_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"

  uri = var.lambda_invoke_arn
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway-${var.endpoint_name}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.execution_arn}/*/*"
}

# Deployment
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = var.api_id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_integration.lambda_integration.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id   = var.api_id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = "prod"
}