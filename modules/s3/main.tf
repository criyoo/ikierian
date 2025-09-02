# Raw Data & Processed Data Buckets
resource "aws_s3_bucket" "main" {
  for_each = {
    raw_data_bucket       = "${var.project_name}-${var.environment}-raw-data-"
    processed_data_bucket = "${var.project_name}-${var.environment}-processed-data-"
  }

  bucket_prefix = each.value

  tags = {
    Name        = each.key
    Environment = var.environment
    Project     = var.project_name
  }
}

# Bucket Versioning
resource "aws_s3_bucket_versioning" "main" {
  for_each = aws_s3_bucket.main

  bucket = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Bucket Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  for_each = aws_s3_bucket.main

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "main" {
  for_each = aws_s3_bucket.main

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  for_each = aws_s3_bucket.main

  bucket = each.value.id

  rule {
    id     = "${each.key}_lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

# S3 Event Notification for Lambda Trigger
resource "aws_s3_bucket_notification" "main" {
  bucket = aws_s3_bucket.main["raw_data_bucket"].id

  lambda_function {
    lambda_function_arn = var.lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = ""
    filter_suffix       = ".json"
  }

  depends_on = [var.lambda_permission]
}

# Auto upload sample data to raw data bucket
resource "aws_s3_object" "main" {
  bucket = aws_s3_bucket.main["raw_data_bucket"].id

  key    = "ikerian_sample.json"
  source = local.data_file
  etag   = filemd5(local.data_file)

  depends_on = [
    aws_s3_bucket.main,
    aws_s3_bucket_public_access_block.main,
    var.lambda_function
  ]

  tags = {
    Name        = "ikerian-sample-data"
    Environment = var.environment
    Project     = var.project_name
  }
}
