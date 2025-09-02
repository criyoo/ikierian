variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  type        = string
}

variable "raw_data_bucket_name" {
  description = "Name of the raw data bucket"
  type        = string
}

variable "processed_data_bucket_name" {
  description = "Name of the processed data bucket"
  type        = string
}

variable "raw_data_bucket_arn" {
  description = "ARN of the raw data bucket"
  type        = string
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 300
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 128
}
