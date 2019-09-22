output "function_name" {
  value = aws_lambda_function.nmm_app.function_name
}

output "lambda_invoke_uri" {
  value = aws_lambda_function.nmm_app.invoke_arn
}