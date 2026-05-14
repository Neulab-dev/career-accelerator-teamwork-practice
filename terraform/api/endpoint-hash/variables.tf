variable "rest_api_config" {
  type = object({
    api_id           = string
    root_resource_id = string
    execution_arn    = string
  })
  description = "Configuration for the REST API (ID, root resource ID, and execution ARN)."
}

variable "prefix" {
  type        = string
  description = "A prefix to be used for naming resources."
}

variable "table_arn" {
  type        = string
  description = "The ARN of the DynamoDB table."
}

variable "hash_length" {
  type        = number
  description = "The length of the generated hash."
}

variable "max_hash_attempts" {
  type        = number
  description = "The maximum number of attempts to generate a unique hash."
}

variable "private_subnets_ids" {
  type        = list(string)
  description = "The ids for the subnets"
}

variable "lambda_kms_key_arn" {
  type        = string
  description = "KMS key ARN used to encrypt Lambda environment variables"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID used by the endpoint resources"
}

variable "max_concurrent_executions" {
  type        = number
  description = "The maximum number of concurrent lambda executions"
}

variable "code_signing_config" {
  type = object({
    code_signing_bucket_id = string
    signing_profile_arn    = string
    signing_config_arn     = string
  })
}

variable "dynamodb_kms_key_arn" {
  type        = string
  description = "KMS key ARN used to encrypt the DynamoDB table."
}