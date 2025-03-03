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

#####################################################################################
# S3
#####################################################################################

variable "s3_bucket_name" {
  description = "S3バケットの名前"
  type        = string
}

variable "s3_acl" {
  description = "バケットのアクセスコントロールリスト"
  type        = string
  default     = "private"
}

variable "s3_force_destroy" {
  description = "バケットを強制的に削除するかどうか"
  type        = bool
  default     = false
}

variable "s3_versioning_enabled" {
  description = "バージョニングを有効にするかどうか"
  type        = bool
  default     = false
}

variable "s3_sse_enabled" {
  description = "サーバーサイド暗号化を有効にするかどうか"
  type        = bool
  default     = true
}

variable "s3_kms_key_id" {
  description = "暗号化に使用するKMSキーのID"
  type        = string
  default     = null
}

variable "s3_lifecycle_rules" {
  description = "ライフサイクルルールの設定"
  type        = any
  default     = []
}

#####################################################################################
# ECR
#####################################################################################

variable "dev_repos" {
  description = "開発環境のECRリポジトリ設定"
  type = map(object({
    repo_names         = list(string)
    repo_access_arns   = list(string)
    lambda_access_arns = list(string)
  }))
  default = {}
}

variable "ga_role_names" {
  description = "GitHub Actions用のIAMロール名のリスト"
  type        = list(string)
  default     = []
}

variable "github_oidc_provider_arn" {
  description = "GitHub OIDC プロバイダーのARN"
  type        = string
}
