variable "project_name" {
  description = "Project name"
  type        = string
  default     = "terraform-dojo"
}

variable "environment_name" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "stack_name" {
  description = "Stack name"
  type        = string
  default     = "synthetic-monitoring-pipeline"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}
