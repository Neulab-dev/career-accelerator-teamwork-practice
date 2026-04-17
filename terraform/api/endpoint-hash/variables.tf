variable "rest_api_config" {
  type = object({
    api_id = string
    root_resource_id = string
    execution_arn = string
  })
  description = "Rest API configuration"
}
#TODO add description to the variables
variable "prefix" {
  type = string
}

variable "table_arn" {
  type = string
}

variable "hash_length" {
  type = number
}

variable "max_hash_attempts" {
  type = number
}