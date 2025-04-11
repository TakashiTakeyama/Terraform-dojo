variable "tgw_name" {
  description = "Transit Gatewayの名前"
  type        = string
  default     = "my-tgw"
}

variable "ram_principals" {
  description = "Transit Gatewayを共有するAWSアカウントIDのリスト"
  type        = list(string)
  default     = []
}

variable "vpc_name" {
  description = "VPCの名前"
  type        = string
  default     = "tgw-vpc"
}

variable "vpc_cidr" {
  description = "VPCのCIDRブロック"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "プライベートサブネットのCIDRブロックリスト"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}
