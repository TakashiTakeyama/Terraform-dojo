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

#####################################################################################
# KMS
#####################################################################################

variable "key_administrators" {
  description = "KMSキーの管理者権限を付与するIAMユーザーのARNのリスト"
  type        = list(string)
}

variable "aliases" {
  description = "KMSキーに付与するエイリアス名のリスト"
  type        = list(string)
}

#####################################################################################
# IAM
#####################################################################################

variable "iam_user_name" {
  description = "IAMユーザーの名前"
  type        = string
}

variable "create_access_key" {
  description = "アクセスキーを作成するかどうか"
  type        = bool
  default     = true
}

variable "create_login_profile" {
  description = "ログインプロファイルを作成するかどうか"
  type        = bool
  default     = true
}

variable "password_reset_required" {
  description = "パスワードリセットが必要かどうか"
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "ユーザーを強制的に削除するかどうか"
  type        = bool
  default     = true
}

variable "iam_policy_arns" {
  description = "IAMポリシーのARNのリスト"
  type        = list(string)
}




