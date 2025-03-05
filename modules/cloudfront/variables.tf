variable "aliases" {
  description = "CloudFrontディストリビューションのエイリアス（カスタムドメイン）"
  type        = list(string)
  default     = []
}

variable "comment" {
  description = "CloudFrontディストリビューションの説明"
  type        = string
  default     = "Managed by Terraform"
}

variable "enabled" {
  description = "CloudFrontディストリビューションの有効/無効"
  type        = bool
  default     = true
}

variable "is_ipv6_enabled" {
  description = "IPv6サポートの有効/無効"
  type        = bool
  default     = true
}

variable "price_class" {
  description = "使用するエッジロケーションの範囲"
  type        = string
  default     = "PriceClass_100" # 北米、欧州、アジア太平洋の主要地域
}

variable "origin_access_identities" {
  description = "S3バケットアクセス用のOrigin Access Identityの設定"
  type        = string
  default     = "CloudFront OAI"
}

variable "logging_config_bucket" {
  description = "CloudFrontのアクセスログを保存するS3バケットのドメイン名"
  type        = string
}

variable "s3_origin_config_domain_name" {
  description = "S3バケットオリジンのドメイン名"
  type        = string
}

variable "viewer_certificate_acm_certificate_arn" {
  description = "HTTPS通信に使用するACM証明書のARN"
  type        = string
}
