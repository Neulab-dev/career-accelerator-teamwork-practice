variable "prefix" {
  type = string
}

variable "table_name" {
  type = string
}

variable "hash_length" {
  type    = number
  default = 6
}

variable "max_hash_attempts" {
  type    = number
  default = 10
}