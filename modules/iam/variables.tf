variable "user_name" {
  description = "作成するIAMユーザーの名前"
  type        = string
}

variable "create_access_key" {
  description = "アクセスキーを作成するかどうか"
  type        = bool
  default     = false
}

variable "create_login_profile" {
  description = "ログインプロファイルを作成するかどうか"
  type        = bool
  default     = false
}

variable "password_reset_required" {
  description = "初回ログイン時にパスワードリセットを要求するかどうか"
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "ユーザーを強制的に削除するかどうか"
  type        = bool
  default     = false
}

variable "policy_arns" {
  description = "ユーザーにアタッチするポリシーのARNのリスト"
  type        = list(string)
  default     = []
} 