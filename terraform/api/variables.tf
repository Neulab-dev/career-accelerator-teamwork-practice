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