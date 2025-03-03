variable "vpc_name" {
  description = "VPCの名前"
  type        = string
}

variable "destination_s3_arn" {
  description = "VPC Flow Logsの出力先S3バケットのARN"
  type        = string
  default     = null # CloudWatch Logsを使用する場合はnullのままで良い
}
