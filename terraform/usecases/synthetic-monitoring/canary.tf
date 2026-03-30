# Canary はデフォルトでは停止状態で作成される（start_canary = false）。
# 実行方法は以下のいずれか:
#   1. オンデマンド: aws synthetics start-canary --name <canary-name>
#   2. CodePipeline: リリースパイプラインのステップから start-canary を呼び出す
# 定期実行（cron）が必要な場合は start_canary = true に変更すれば、
# schedule.expression に従って自動実行される。
#
# canary コードは CodePipeline (synthetic-monitoring-pipeline) の Build ステージで
# S3 にアップロードされ、続く Deploy ステージの terraform apply でこのリソースが更新される。
# s3_version に data.aws_s3_object の version_id を紐づけることで、
# zip アップロード後の terraform apply で自動的に差分検知→反映される。

resource "aws_synthetics_canary" "web" {
  name                 = "${local.name_prefix}-web"
  artifact_s3_location = "s3://${aws_s3_bucket.canary_artifacts.id}/web/"
  execution_role_arn   = aws_iam_role.canary_execution.arn
  runtime_version      = var.canary_runtime_version
  handler              = "index.handler"
  start_canary         = false
  s3_bucket            = data.aws_s3_bucket.canary_deployments.bucket
  s3_key               = "web-scenario/canary.zip"
  s3_version           = data.aws_s3_object.web_canary_code.version_id

  schedule {
    expression = var.canary_schedule_expression
  }

  run_config {
    timeout_in_seconds = 120

    environment_variables = {
      TARGET_URL           = var.web_target_url
      WEB_SIGNIN_SECRET_ID = aws_secretsmanager_secret.web_signin.arn
    }
  }
}

resource "aws_synthetics_canary" "api" {
  name                 = "${local.name_prefix}-api"
  artifact_s3_location = "s3://${aws_s3_bucket.canary_artifacts.id}/api/"
  execution_role_arn   = aws_iam_role.canary_execution.arn
  runtime_version      = var.canary_runtime_version
  handler              = "index.handler"
  start_canary         = false
  s3_bucket            = data.aws_s3_bucket.canary_deployments.bucket
  s3_key               = "api-scenario/canary.zip"
  s3_version           = data.aws_s3_object.api_canary_code.version_id

  schedule {
    expression = var.canary_schedule_expression
  }

  run_config {
    timeout_in_seconds = 60

    environment_variables = {
      API_ENDPOINT    = var.api_target_url
      API_HEALTH_PATH = var.api_health_path
    }
  }
}
