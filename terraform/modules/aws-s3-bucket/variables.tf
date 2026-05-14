variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "force_destroy" {
  description = "Whether to allow the bucket to be destroyed even if it contains objects"
  type        = bool
  default     = true
}
