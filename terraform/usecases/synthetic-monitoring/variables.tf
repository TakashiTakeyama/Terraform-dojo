variable "environment_name" {
  type        = string
  description = "Environment name (e.g. dev, stg, prod)"
}

variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
}

variable "web_target_url" {
  type        = string
  description = "URL that the web (browser) canary navigates to and verifies"
}

variable "api_target_url" {
  type        = string
  description = "Base URL of the API that the API canary calls for health check"
}

variable "api_health_path" {
  type        = string
  default     = "/health"
  description = "Path appended to api_target_url for the API canary health check"
}

variable "canary_schedule_expression" {
  type        = string
  default     = "rate(0 minute)"
  description = "Schedule expression for canaries. rate(0 minute) = run once on start. Use rate(5 minutes) for periodic execution."
}

variable "canary_runtime_version" {
  type        = string
  default     = "syn-nodejs-playwright-6.0"
  description = "CloudWatch Synthetics runtime version"
}

variable "enable_log_forwarding" {
  type        = bool
  default     = false
  description = "Whether to forward canary logs to an external Lambda (e.g. Datadog Forwarder)"
}

variable "log_forwarder_lambda_name" {
  type        = string
  default     = ""
  description = "Lambda function name of the log forwarder. Required when enable_log_forwarding is true."
}
