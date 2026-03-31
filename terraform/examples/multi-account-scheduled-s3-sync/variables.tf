variable "aws_region" {
  type        = string
  description = "AWS region for this sample."
  default     = "ap-northeast-1"
}

variable "stage" {
  type        = string
  description = "Environment prefix for resource names."
  default     = "dev"
}

variable "project" {
  type        = string
  description = "Project prefix for resource names."
  default     = "example-s3-sync"
}

variable "schedule_expression" {
  type        = string
  description = "EventBridge schedule expression (UTC)."
  default     = "cron(0 2 * * ? *)"
}
