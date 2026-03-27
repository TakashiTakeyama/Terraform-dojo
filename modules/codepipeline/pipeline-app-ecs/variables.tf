variable "name_prefix" {
  description = "リソース名の接頭辞（github-buildchain と同じ制約）。"
  type        = string
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

variable "github_connection_arn" {
  description = "GitHub 用 CodeStar Connections / CodeConnections の ARN。"
  type        = string
}

variable "full_repository_id" {
  description = "owner/repo 形式。"
  type        = string
}

variable "branch_name" {
  description = "取得するブランチ名。"
  type        = string
}

variable "source_detect_changes" {
  description = "ソース変更検知。trigger 指定時は github-buildchain 側で false に上書き。"
  type        = bool
  default     = true
}

variable "trigger" {
  description = "V2 トリガー（ブランチ・パス・タグ）。"
  type = object({
    branches   = optional(list(string), [])
    file_paths = optional(list(string), [])
    tags       = optional(list(string), [])
  })
  default = null
}

variable "source_output_artifact_format" {
  description = "Docker ビルドのみなら CODE_ZIP でよい。git 履歴が必要なら CODEBUILD_CLONE_REF。"
  type        = string
  default     = "CODE_ZIP"

  validation {
    condition     = contains(["CODE_ZIP", "CODEBUILD_CLONE_REF"], var.source_output_artifact_format)
    error_message = "source_output_artifact_format は CODE_ZIP または CODEBUILD_CLONE_REF です。"
  }
}

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
  description = "create_artifact_bucket=true のときのグローバル一意バケット名。未指定時は自動生成。"
  type        = string
  default     = null
}

variable "artifact_store_kms_key_arn" {
  description = "成果物の SSE-KMS に使う KMS キー ARN。未指定時は S3 のデフォルト暗号化に任せる。"
  type        = string
  default     = null
}

variable "artifact_bucket_force_destroy" {
  description = "作成する成果物バケットを terraform destroy で中身付き削除するか。"
  type        = bool
  default     = false
}

variable "artifact_lifecycle_expiration_days" {
  description = "成果物バケットの有効期限（日数）。0 のとき lifecycle ルールを作成しない。"
  type        = number
  default     = 30
}

# --- Build（Docker build / ECR push 等）---

variable "build_buildspec_path" {
  description = "buildspec_inline が空のときの相対パス。Docker 用は ci/docker-build.buildspec.yml 等を推奨。"
  type        = string
  default     = "buildspec.yml"
}

variable "build_buildspec_inline" {
  description = "非空なら buildspec_path より優先されるインライン buildspec。"
  type        = string
  default     = null
}

variable "build_image" {
  description = "Build 段の CodeBuild イメージ。"
  type        = string
  default     = "aws/codebuild/standard:7.0"
}

variable "build_compute_type" {
  description = "Build 段のコンピュートタイプ。Docker ビルドでは MEDIUM 以上を検討。"
  type        = string
  default     = "BUILD_GENERAL1_MEDIUM"
}

variable "build_privileged_mode" {
  description = "Docker デーモン利用のため既定 true。"
  type        = bool
  default     = true
}

variable "build_environment_variables" {
  description = "Build 段に渡す PLAINTEXT 環境変数。"
  type        = map(string)
  default     = {}
}

variable "build_stage_iam_policy_json" {
  description = "ビルド段の追加 IAM（例: ecr:GetAuthorizationToken, ecr:BatchCheckLayerAvailability …）。"
  type        = string
  default     = null
}

variable "build_namespace" {
  description = "Deploy 段でイメージタグ等を参照する場合の namespace（任意）。"
  type        = string
  default     = null
}

# --- Deploy（タスク定義登録・サービス更新等）---

variable "deploy_buildspec_path" {
  description = "deploy_buildspec_inline が空のときの相対パス。"
  type        = string
  default     = "deploy.buildspec.yml"
}

variable "deploy_buildspec_inline" {
  description = "非空なら deploy_buildspec_path より優先されるインライン buildspec。"
  type        = string
  default     = null
}

variable "deploy_image" {
  description = "Deploy 段の CodeBuild イメージ。"
  type        = string
  default     = "aws/codebuild/standard:7.0"
}

variable "deploy_compute_type" {
  description = "Deploy 段のコンピュートタイプ。"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "deploy_privileged_mode" {
  description = "Deploy 段で Docker デーモンが不要なら false（既定）。"
  type        = bool
  default     = false
}

variable "deploy_environment_variables" {
  description = "Deploy 段に渡す PLAINTEXT 環境変数。"
  type        = map(string)
  default     = {}
}

variable "deploy_stage_iam_policy_json" {
  description = "デプロイ段の IAM（ecs:RegisterTaskDefinition, ecs:UpdateService 等）。"
  type        = string
  default     = null
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
  description = "各 CodeBuild ロールに共通でアタッチする AWS 管理ポリシー ARN。本番では最小限に。"
  type        = list(string)
  default     = []
}

variable "pipeline_additional_iam_policy_json" {
  description = "CodePipeline ロールにマージする追加 IAM ポリシー JSON。"
  type        = string
  default     = null
}

variable "execution_mode" {
  description = "SUPERSEDED、QUEUED、または PARALLEL。"
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
