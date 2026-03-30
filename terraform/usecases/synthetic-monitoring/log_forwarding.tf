# Canary 実行ログを外部の Log Forwarder Lambda（例: Datadog Forwarder）に転送する。
# enable_log_forwarding = true の場合のみリソースが作成される。
#
# Canary は Lambda として動作し、ログを /aws/lambda/cwsyn-<name>-<id> に出力する。
# engine_arn から Lambda 関数名を抽出し、ロググループ名を構成する。
#
# ロググループは data ソースではなく resource として作成する。
# Canary 作成直後は Lambda が未実行のためロググループが存在せず、
# data ソースだと "empty result" エラーになるため。

# engine_arn（例: arn:aws:lambda:REGION:ACCOUNT:function:FUNC_NAME:VERSION）の
# 7番目の要素（index 6）が Lambda 関数名。
locals {
  web_canary_lambda_name = element(split(":", aws_synthetics_canary.web.engine_arn), 6)
  api_canary_lambda_name = element(split(":", aws_synthetics_canary.api.engine_arn), 6)
}

data "aws_lambda_function" "log_forwarder" {
  count         = var.enable_log_forwarding ? 1 : 0
  function_name = var.log_forwarder_lambda_name
}

resource "aws_cloudwatch_log_group" "web_canary" {
  name              = "/aws/lambda/${local.web_canary_lambda_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "api_canary" {
  name              = "/aws/lambda/${local.api_canary_lambda_name}"
  retention_in_days = 30
}

# --- Web Canary logs → Log Forwarder ---

resource "aws_cloudwatch_log_subscription_filter" "web_canary" {
  count           = var.enable_log_forwarding ? 1 : 0
  name            = "${local.name_prefix}-web-canary-to-forwarder"
  log_group_name  = aws_cloudwatch_log_group.web_canary.name
  filter_pattern  = ""
  destination_arn = data.aws_lambda_function.log_forwarder[0].arn
}

resource "aws_lambda_permission" "web_canary_to_forwarder" {
  count         = var.enable_log_forwarding ? 1 : 0
  statement_id  = "allow-web-canary-logs"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.log_forwarder[0].function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.web_canary.arn}:*"
}

# --- API Canary logs → Log Forwarder ---

resource "aws_cloudwatch_log_subscription_filter" "api_canary" {
  count           = var.enable_log_forwarding ? 1 : 0
  name            = "${local.name_prefix}-api-canary-to-forwarder"
  log_group_name  = aws_cloudwatch_log_group.api_canary.name
  filter_pattern  = ""
  destination_arn = data.aws_lambda_function.log_forwarder[0].arn
}

resource "aws_lambda_permission" "api_canary_to_forwarder" {
  count         = var.enable_log_forwarding ? 1 : 0
  statement_id  = "allow-api-canary-logs"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.log_forwarder[0].function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.api_canary.arn}:*"
}
