variable "vpc_name" {
  description = "メインVPCの名前"
  type        = string
}

variable "workspaces_name" {
  description = "Terraform Cloudのワークスペース名"
  type        = string
}

variable "ssm_ec2" {
  description = "SSM EC2の設定"
  type = object({
    instance_type          = string
    vpc_security_group_ids = optional(list(string))
    subnet_id              = string
  })
}

variable "user_data" {
  description = "ユーザーデータ"
  type        = string
}

variable "ami_name" {
  description = "AMIの名前"
  type        = string
}
