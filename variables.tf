variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Name of Environment (e.g. dev, stage, prod)"
  type        = string
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
}
