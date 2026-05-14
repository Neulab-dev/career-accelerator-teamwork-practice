output "table_arn" {
  value       = aws_dynamodb_table.shortly.arn
  description = "ARN of the DynamoDB table"
}

output "kms_key_arn" {
  value       = aws_kms_key.dynamodb.arn
  description = "ARN of the KMS key used for DynamoDB table encryption"
}
