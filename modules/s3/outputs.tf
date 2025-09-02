output "raw_data_bucket" {
  description = "ARN of the raw data bucket"
  value       = aws_s3_bucket.main["raw_data_bucket"]
}

output "processed_data_bucket" {
  description = "ARN of the processed data bucket"
  value       = aws_s3_bucket.main["processed_data_bucket"]
}
