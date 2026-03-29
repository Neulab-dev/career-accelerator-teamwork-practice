terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.5"
}

provider "aws" {
  region = "eu-central-1"
}

variable "prefix" {
  default = "shortly"
}

variable "table_name" {
  default = "shortly-urls"
}

#DynamoDB
resource "aws_dynamodb_table" "urls" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "hash"

  attribute {
    name = "hash"
    type = "S"
  }
}

#Lambda modul
module "hash_lambda" {
  source = "./hash-lambda"

  prefix              = var.prefix
  table_name          = aws_dynamodb_table.urls.name
  hash_length         = 6
  max_hash_attempts   = 10
}

output "lambda_name" {
  value = module.hash_lambda.lambda_name
}

output "lambda_arn" {
  value = module.hash_lambda.lambda_arn
}

output "dynamodb_table" {
  value = aws_dynamodb_table.urls.name
}