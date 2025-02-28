#####################################################################################
# Common
#####################################################################################

variable "region" {
  description = "Default Region"
  type        = string
  default     = "ap-northeast-1"
}

variable "vpc_name" {
  description = "メインVPCの名前"
  type        = string
}

#####################################################################################
# SSM EC2
#####################################################################################

variable "workspaces_name" {
  description = "Terraform Cloudのワークスペース名"
  type        = string
}

variable "ami_name" {
  description = "AMIの名前"
  type        = string
}

variable "ssm_ec2" {
  description = "SSM EC2の設定"
  type = object({
    instance_type = string
    subnet_id     = string
  })
}

variable "user_data" {
  description = "ユーザーデータ"
  type        = string
}
