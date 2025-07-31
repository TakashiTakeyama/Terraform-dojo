########################################################
# Common
########################################################

variable "vpc_name" {
  description = "VPC名"
  type        = string
  default     = "dev-hoge-voice-vpc"
}

variable "region_name" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "environment_name" {
  description = "環境名"
  type        = string
}

variable "resource_prefix" {
  description = "リソース名のプレフィックス"
  type        = string
}

variable "tags" {
  description = "タグ"
  type        = map(string)
}

########################################################
# Lambda
########################################################

variable "python_runtime" {
  description = "Python実行環境"
  type        = string
  default     = "python3.13"
}

variable "lambda_role_arn" {
  description = "Lambda実行用IAMロールのARN"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3バケット名"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3バケットのARN"
  type        = string
}
