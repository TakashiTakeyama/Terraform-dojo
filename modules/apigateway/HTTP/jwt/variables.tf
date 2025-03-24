variable "name" {
  description = "API Gatewayの名前"
  type        = string
}

variable "description" {
  description = "API Gatewayの説明"
  type        = string
}

variable "lambda_function_arn" {
  description = "統合するLambda関数のARN"
  type        = string
}

variable "domain_name" {
  description = "APIのカスタムドメイン名"
  type        = string
  default     = null
}
