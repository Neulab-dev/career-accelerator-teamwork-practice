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

locals {
  prefix            = "shortly"
  table_name        = "shortly-urls"
  hash_length       = 6
  max_hash_attempts = 10
  table_arn         = aws_dynamodb_table.shortly.arn
}
# DynamoDB
resource "aws_dynamodb_table" "shortly" {
  name         = local.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "hash"

  attribute {
    name = "hash"
    type = "S"
  }
}

module "api" {
  source = "./api"

  prefix               = local.prefix
  table_arn            = local.table_arn
  table_name           = local.table_name
  hash_length          = local.hash_length
  max_hash_attempts    = local.max_hash_attempts
}