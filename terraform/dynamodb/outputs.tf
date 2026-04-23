output "table_arn" {
  value = aws_dynamodb_table.shortly.arn
  description = "ARN of the DynamoDB table"
}