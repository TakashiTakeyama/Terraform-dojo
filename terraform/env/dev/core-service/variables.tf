variable "project_name" {
  description = "プロジェクト名"
  type        = string
  default     = "terraform-dojo"
}

variable "environment_name" {
  description = "環境名"
  type        = string
  default     = "dev"
}

variable "stack_name" {
  description = "スタック名"
  type        = string
  default     = "core-service"
}

variable "region" {
  description = "AWS リージョン"
  type        = string
  default     = "ap-northeast-1"
}
