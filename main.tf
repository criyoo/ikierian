
# S3 Buckets
module "s3_buckets" {
  source = "./modules/s3"

  project_name      = var.project_name
  environment       = var.environment
  lambda_function   = module.lambda.lambda_function
  lambda_permission = module.lambda.lambda_permission
}

# IAM Roles and Policies
module "iam" {
  source = "./modules/iam"

  project_name              = var.project_name
  environment               = var.environment
  raw_data_bucket_arn       = module.s3_buckets.raw_data_bucket.arn
  processed_data_bucket_arn = module.s3_buckets.processed_data_bucket.arn
}

# Lambda Function
module "lambda" {
  source = "./modules/lambda"

  project_name               = var.project_name
  environment                = var.environment
  lambda_role_arn            = module.iam.lambda_role.arn
  raw_data_bucket_name       = module.s3_buckets.raw_data_bucket.bucket
  processed_data_bucket_name = module.s3_buckets.processed_data_bucket.bucket
  raw_data_bucket_arn        = module.s3_buckets.raw_data_bucket.arn
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-data-processor"
  retention_in_days = 14

  tags = {
    Name        = "${var.project_name}-${var.environment}-lambda-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

