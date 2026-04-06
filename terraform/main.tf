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
}

module "hash_lambda" {
  source = "./hash-lambda"

  prefix            = local.prefix
  table_name        = local.table_name
}