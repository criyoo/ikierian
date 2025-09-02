variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Name of Environment"
  type        = string
}

variable "lambda_permission" {
  description = "Lambda permission for S3 trigger"
  type        = any
}

variable "lambda_function" {
  description = "Lambda function for auto upload of sample data"
  type        = any
}
