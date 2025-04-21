################################################################################
# Configuration
################################################################################

variable "region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "name" {
  description = "リソース名のプレフィックス"
  type        = string
  default     = "ex-cloudwatch"
}

variable "vpc_cidr" {
  description = "VPCのCIDRブロック"
  type        = string
  default     = "10.0.0.0/16"
}

variable "container_name" {
  description = "コンテナ名"
  type        = string
  default     = "ecsdemo-frontend"
}

variable "container_port" {
  description = "コンテナポート"
  type        = number
  default     = 3000
}
