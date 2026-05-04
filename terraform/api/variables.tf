variable "prefix" {
  type        = string
  description = "Environment prefix"
}

variable "table_arn" {
  type        = string
  description = "The ARN of the DynamoDB table."
}

variable "hash_length" {
  type        = number
  description = "The length of the hash to be generated."
}

variable "max_hash_attempts" {
  type        = number
  description = "The maximum number of attempts to generate a unique hash."
}

variable "private_subnets_ids" {
  type        = list(string)
  description = "The ids for the subnets"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID used by API-related Lambda resources"
}