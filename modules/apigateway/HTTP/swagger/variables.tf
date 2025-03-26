variable "company_name" {
  type        = string
  description = "会社名"
}

variable "env" {
  description = "環境"
  type        = string
}

variable "product_name" {
  type        = string
  description = "製品名"
}

variable "project_name" {
  type        = string
  description = "プロジェクト名"
}

variable "apis" {
  type = map(object({
    api_name                = string
    api_stage_name          = string
    api_resource_path       = string
    api_method              = string
    lambda_name             = string
    api_key_name            = string
    api_usage_plan_name     = string
    usage_plan_quota_limit  = string
    usage_plan_quota_period = string
  }))
}

variable "api_type" {
  description = "APIタイプ"
  type        = string
}

variable "api_gateway_endpoint_id" {
  description = "API Gatewayエンドポイントのid"
  type        = string
}

variable "apigateway_log_role_arn" {
  description = "API Gatewayログ用のロールARN"
  type        = string
}

variable "api_log_retention_days" {
  description = "APIログの保持日数"
  type        = number
}

variable "api_log_group_arns" {
  description = "APIロググループのARN"
  type        = map(string)
}

variable "lambda_function_arns" {
  description = "Lambda関数ARNのマップ"
  type = map(string)
}

variable "usage_plan_throttle_burst_limit" {
  description = "使用プランのスロットリングバーストリミット"
  type        = string
}

variable "usage_plan_throttle_rate_limit" {
  description = "使用プランのスロットリングレートリミット"
  type        = string
}

variable "api_key_type" {
  description = "APIキータイプ"
  type        = string
}

variable "lambda_permission_statement_id" {
  description = "Lambda権限のステートメントID"
  type        = string
}

variable "lambda_permission_action" {
  description = "Lambda権限のアクション"
  type        = string
}

variable "lambda_function_names" {
  description = "Lambda関数名のマップ"
  type = map(string)
}

variable "lambda_permission_principal" {
  description = "Lambda権限のプリンシパル"
  type        = string
}

variable "cloudwatch_metrics_enabled" {
  description = "CloudWatchメトリクスの有効化フラグ"
  type        = bool
}

variable "cloudwatch_logging_level" {
  description = "CloudWatchログレベル"
  type        = string
}

variable "cloudwatch_data_trace_enabled" {
  description = "CloudWatchデータトレースの有効化フラグ"
  type        = bool
}