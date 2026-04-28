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
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }
  // without it -> No backups.
  point_in_time_recovery {
    enabled = true
  }
  /*
      KMS:
          AWS default encryption exists
          but Checkov wants a custom KMS key not the default AWS one
   */
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }
}

// KMS
resource "aws_kms_key" "dynamodb" {
  description             = "KMS key for Shortly DynamoDB table"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "dynamodb" {
  name          = "alias/${local.table_name}"
  target_key_id = aws_kms_key.dynamodb.key_id
}

module "api" {
  source = "./api"

  prefix            = local.prefix
  table_arn         = local.table_arn
  hash_length       = local.hash_length
  max_hash_attempts = local.max_hash_attempts
}
