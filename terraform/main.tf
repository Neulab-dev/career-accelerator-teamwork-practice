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
  hash_length       = 6
  max_hash_attempts = 10
}

module "api" {
  source = "./api"

  prefix               = local.prefix
  table_arn            = module.dynamodb.table_arn
  hash_length          = local.hash_length
  max_hash_attempts    = local.max_hash_attempts
  private_subnets_ids  = module.network.private_subnet_ids
  vpc_id               = module.network.vpc_id
  dynamodb_kms_key_arn = module.dynamodb.kms_key_arn
}

module "dynamodb" {
  source = "./dynamodb"

  prefix = local.prefix
}

module "network" {
  source = "./network"

  prefix = local.prefix
}
