variable "key_administrators" {
  description = "KMSキーの管理者権限を付与するIAMユーザーのARNのリスト"
  type        = list(string)
}

variable "aliases" {
  description = "KMSキーに付与するエイリアス名のリスト"
  type        = list(string)
}
