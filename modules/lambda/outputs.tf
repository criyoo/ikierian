output "lambda_function" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.data_processor
}

output "lambda_permission" {
  description = "Lambda permission for S3 trigger"
  value       = aws_lambda_permission.s3_trigger
}
