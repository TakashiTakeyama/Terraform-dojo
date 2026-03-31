variable "aws_region" {
  type        = string
  description = "AWS region for this sample (DataSync locations and task must match)."
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
  default     = "example-datasync"
}

variable "enable_task" {
  type        = bool
  description = "Create aws_datasync_task when true."
  default     = true
}
