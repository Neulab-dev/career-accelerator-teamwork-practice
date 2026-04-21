output "lambda_name" {
  value = aws_lambda_function.hash_lambda.function_name
}

output "invoke_lambda_arn" {
  value = aws_lambda_function.hash_lambda.invoke_arn
}