variable "bucket_name" {
  description = "S3バケットの名前"
  type        = string
}

variable "acl" {
  description = "バケットのアクセスコントロールリスト"
  type        = string
  default     = "private"
}

variable "force_destroy" {
  description = "バケットを強制的に削除するかどうか"
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "バージョニングを有効にするかどうか"
  type        = bool
  default     = false
}

variable "sse_enabled" {
  description = "サーバーサイド暗号化を有効にするかどうか"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "暗号化に使用するKMSキーのID"
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  description = "ライフサイクルルールの設定"
  type        = any
  default     = []
}

variable "bucket_policy" {
  description = "バケットポリシー"
  type        = string
  default     = ""
}
