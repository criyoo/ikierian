# Create ZIP file for Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.root}/files/lambda/ikerian_data_processor.py"
  output_path = "${path.root}/files/lambda/ikerian_data_processor.zip"
}

# Lambda Function
resource "aws_lambda_function" "data_processor" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "${var.project_name}-${var.environment}-data-processor"
  role          = var.lambda_role_arn
  handler       = "ikerian_data_processor.lambda_handler"
  runtime       = "python3.9"
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size

  environment {
    variables = {
      RAW_DATA_BUCKET       = var.raw_data_bucket_name
      PROCESSED_DATA_BUCKET = var.processed_data_bucket_name
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-data-processor"
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [
    data.archive_file.lambda_zip
  ]
}

# Permission for S3 to Trigger Lambda Function
resource "aws_lambda_permission" "s3_trigger" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.raw_data_bucket_arn
}
