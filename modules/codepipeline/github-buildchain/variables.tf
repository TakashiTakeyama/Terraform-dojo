variable "name_prefix" {
  description = "リソース名の接頭辞。英数字・ハイフン（先頭末尾ハイフン不可）。S3 バケット名に使うため短め推奨。"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.name_prefix))
    error_message = "name_prefix は 1〜63 文字の DNS ラベル互換（小文字・数字・ハイフン）にしてください。"
  }
}

variable "pipeline_name" {
  description = "CodePipeline 名。未指定時は {name_prefix}-pipeline。"
  type        = string
  default     = null
}

variable "tags" {
  description = "全リソースに付与するタグ。"
  type        = map(string)
  default     = {}
}

# --- GitHub（CodeStar Connections / CodeConnections）---

variable "github_connection_arn" {
  description = "GitHub 用 CodeStar Connections または CodeConnections の ARN。"
  type        = string
}

variable "full_repository_id" {
  description = "GitHub の owner/repo 形式。"
  type        = string
}

variable "branch_name" {
  description = "取得するブランチ名。"
  type        = string
}

variable "source_detect_changes" {
  description = "ソースの変更検知を有効にする（接続側の設定にも依存）。trigger を指定した場合は自動で false になるため、通常は既定のままで問題ない。"
  type        = bool
  default     = true
}

variable "trigger" {
  description = <<-EOT
    V2 パイプラインのトリガー設定。null のとき source_detect_changes に委ねる。
    branches / file_paths を組み合わせてプッシュイベントをフィルタリングできる。
    tags を指定するとタグプッシュで起動する（branches と排他でないが混在は非推奨）。
    trigger を指定すると source_detect_changes は自動で false に上書きされる。
  EOT
  type = object({
    branches   = optional(list(string), [])
    file_paths = optional(list(string), [])
    tags       = optional(list(string), [])
  })
  default = null
}

variable "source_output_artifact_format" {
  description = "CODE_ZIP または CODEBUILD_CLONE_REF。"
  type        = string
  default     = "CODE_ZIP"

  validation {
    condition     = contains(["CODE_ZIP", "CODEBUILD_CLONE_REF"], var.source_output_artifact_format)
    error_message = "source_output_artifact_format は CODE_ZIP または CODEBUILD_CLONE_REF です。"
  }
}

# --- 成果物バケット ---

variable "create_artifact_bucket" {
  description = "true のとき専用 S3 バケットを作成。false のとき artifact_s3_bucket_id で既存を指定。"
  type        = bool
  default     = true
}

variable "artifact_s3_bucket_id" {
  description = "create_artifact_bucket=false のとき必須。既存バケット名。"
  type        = string
  default     = null
}

variable "artifact_s3_bucket_name" {
  description = "create_artifact_bucket=true のときのグローバル一意バケット名。未指定時は {account_id}-{name_prefix}-pipeline-artifacts。"
  type        = string
  default     = null
}

variable "artifact_store_kms_key_arn" {
  description = "成果物の SSE-KMS に使う KMS キー ARN。未指定時は S3 のデフォルト暗号化に任せる（パイプライン artifact_store に encryption_key を付けない）。"
  type        = string
  default     = null
}

variable "artifact_bucket_force_destroy" {
  description = "作成する成果物バケットを terraform destroy で中身付き削除するか。"
  type        = bool
  default     = false
}

variable "artifact_lifecycle_expiration_days" {
  description = "成果物バケットの有効期限（日数）。0 のとき lifecycle ルールを作成しない。デフォルト 30 日。"
  type        = number
  default     = 30
}

# --- CodeBuild ステージ（上から順にパイプラインへ接続）---

variable "codebuild_stages" {
  description = <<-EOT
    Source 直後から順に実行する CodeBuild ステージ。
    - buildspec_inline: 非 null かつ非空ならインライン buildspec（リポジトリのファイルより優先）
    - buildspec_path: 上記が無い場合、ソース ZIP ルートからの相対パス
    - additional_iam_policy_json: そのステージ専用の IAM ポリシー JSON（デプロイ API 等）。デプロイ段を分けたい場合に第2段へ付与
  EOT
  type = list(object({
    key                        = string
    name                       = string
    namespace                  = optional(string)
    buildspec_inline           = optional(string)
    buildspec_path             = optional(string, "buildspec.yml")
    image                      = optional(string, "aws/codebuild/standard:7.0")
    compute_type               = optional(string, "BUILD_GENERAL1_SMALL")
    environment_type           = optional(string, "LINUX_CONTAINER")
    privileged_mode            = optional(bool, false)
    environment_variables      = optional(map(string), {})
    additional_iam_policy_json = optional(string)
  }))

  validation {
    condition     = length(var.codebuild_stages) >= 1
    error_message = "codebuild_stages は最低 1 要素必要です。"
  }

  validation {
    condition     = length(distinct([for s in var.codebuild_stages : s.key])) == length(var.codebuild_stages)
    error_message = "codebuild_stages[].key は一意である必要があります。"
  }
}

variable "codebuild_timeout_minutes" {
  description = "各 CodeBuild プロジェクトのタイムアウト（分）。"
  type        = number
  default     = 60
}

variable "codebuild_log_retention_days" {
  description = "CodeBuild の CloudWatch Logs 保持日数。"
  type        = number
  default     = 30
}

variable "codebuild_managed_policy_arns" {
  description = "各 CodeBuild ロールに共通でアタッチする AWS 管理ポリシー ARN（空ならなし）。本番では最小限に。"
  type        = list(string)
  default     = []
}

variable "pipeline_additional_iam_policy_json" {
  description = "CodePipeline ロールにマージする追加 IAM ポリシー JSON（手動承認後の独自アクション等）。空ならなし。"
  type        = string
  default     = null
}

variable "execution_mode" {
  description = "SUPERSEDED、QUEUED、または PARALLEL。PARALLEL は同一パイプラインの複数実行を独立して並行動作させる。"
  type        = string
  default     = "QUEUED"

  validation {
    condition     = contains(["SUPERSEDED", "QUEUED", "PARALLEL"], var.execution_mode)
    error_message = "execution_mode は SUPERSEDED、QUEUED、または PARALLEL です。"
  }
}

variable "enable_pipeline_cloudwatch_logs" {
  description = "CodePipeline の実行ログ用 CloudWatch Logs 権限をロールに付与するか。"
  type        = bool
  default     = true
}
