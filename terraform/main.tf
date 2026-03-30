terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.5"
}

#Placeholder for now because api is not done yet
variable "api_id" {}
variable "resource_id" {}
variable "execution_arn" {}

provider "aws" {
  region = "eu-central-1"
}

variable "prefix" {
  default = "shortly"
}

variable "table_name" {
  default = "shortly-urls"
}

module "hash_lambda" {
  source = "./hash-lambda"

  prefix            = var.prefix
  table_name        = var.table_name
  hash_length       = 6
  max_hash_attempts = 10
}

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

output "lambda_name" {
  value = module.hash_lambda.lambda_name
}

output "lambda_arn" {
  value = module.hash_lambda.lambda_arn
}