variable "dev_repos" {
  description = "Dev環境で利用するアプリ用のリポジトリ"
  type        = any
}

variable "ga_role_names" {
  description = "GithubActions用ロール"
  type        = list(string)
}

variable "github_oidc_provider_arn" {
  description = "OIDC用プロバイダーのarn"
  type        = string
}
