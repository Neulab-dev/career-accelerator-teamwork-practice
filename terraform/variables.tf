variable "hash_length" {
  type    = number
  default = 6
}

variable "max_hash_attempts" {
  type    = number
  default = 10
}

variable "prefix" {
  default = "shortly"
}

variable "table_name" {
  default = "shortly-urls"
}