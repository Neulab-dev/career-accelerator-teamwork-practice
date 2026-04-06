output "lambda_name" {
  value = aws_lambda_function.hash_lambda.function_name
}

output "lambda_invoke_arn" {
  value = aws_lambda_function.hash_lambda.invoke_arn
}