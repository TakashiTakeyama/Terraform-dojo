module "synthetic_monitoring" {
  source = "../../../usecases/synthetic-monitoring"

  environment_name = var.environment_name
  project_name     = var.project_name

  web_target_url  = "https://example.com"
  api_target_url  = "https://api.example.com"
  api_health_path = "/health"

  # ログ転送を有効にする場合はコメントを解除する
  # enable_log_forwarding     = true
  # log_forwarder_lambda_name = "my-log-forwarder-function"
}
