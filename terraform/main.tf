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

module "hash_lambda" {
  source = "./hash-lambda"

  prefix            = var.prefix
  table_name        = var.table_name
  hash_length       = 6
  max_hash_attempts = 10
}

output "lambda_name" {
  value = module.hash_lambda.lambda_name
}

output "lambda_arn" {
  value = module.hash_lambda.lambda_arn
}