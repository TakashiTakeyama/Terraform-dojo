# ----------------------------------------------
# AWS API Gateway Swaggerモジュール
# Swaggerファイルを使用してREST APIを作成する
# ----------------------------------------------

# REST API Gateway
resource "aws_api_gateway_rest_api" "rest_api" {
  for_each = var.apis

  # APIの名前とリソース説明を設定
  name        = each.value.name
  description = "Private REST API Gateway for ${each.value.description}"

  # Swaggerテンプレートを使用してAPIを定義
  body = data.template_file.swagger[each.key].rendered

  # エンドポイント設定（プライベートVPCエンドポイント）
  endpoint_configuration {
    # types = ["${var.api_type}"]
    types = ["${each.value.api_type}"]
    # vpc_endpoint_ids = [var.api_gateway_endpoint_id]
    vpc_endpoint_ids = [each.value.api_gateway_endpoint_id]
  }

  # APIのリソースポリシー設定
  # 特定のVPCエンドポイントからのアクセスのみを許可
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "execute-api:Invoke",
        "Resource" : "execute-api:/*/*/*",
        "Condition" : {
          "StringNotEquals" : {
            "aws:SourceVpce" : var.api_gateway_endpoint_id
          }
        }
      },
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "execute-api:Invoke",
        "Resource" : "execute-api:/*/*/*"
      }
    ]
  })
}

# CloudWatchログ用のIAMロールを設定
resource "aws_api_gateway_account" "api_account" {
  cloudwatch_role_arn = var.apigateway_log_role_arn
}

# CloudWatchロググループの作成
resource "aws_cloudwatch_log_group" "api_log_group" {
  for_each = var.apis

  name              = "/aws/apigateway/${var.company_name}-${var.product_name}-${var.project_name}-${var.env}-${each.value.api_name}"
  retention_in_days = var.api_log_retention_days

  tags = {
    Environment = "${var.env}"
  }
}

# APIのデプロイ先となるステージを作成
resource "aws_api_gateway_stage" "api_stage" {
  for_each = var.apis

  deployment_id = aws_api_gateway_deployment.api_deployment[each.key].id
  rest_api_id   = aws_api_gateway_rest_api.rest_api[each.key].id
  stage_name    = each.value.api_stage_name

  # アクセスログ設定
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_log_group[each.key].arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  # X-Rayトレース無効化
  xray_tracing_enabled = false
}

# デプロイ
resource "aws_api_gateway_deployment" "api_deployment" {
  for_each = var.apis

  rest_api_id = aws_api_gateway_rest_api.rest_api[each.key].id

  # 再デプロイトリガー設定
  # APIの内容が変更された場合に再デプロイを実行
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.rest_api[each.key].body,
      data.template_file.swagger[each.key].rendered,
      timestamp()
    ]))
  }

  # 新しいデプロイメントを作成してから古いものを削除
  lifecycle {
    create_before_destroy = true
  }
}

# APIへのアクセスに必要なAPIキーを作成
resource "aws_api_gateway_api_key" "api_key" {
  for_each = var.apis

  name = "${var.company_name}-${var.product_name}-${var.project_name}-${var.env}-${each.value.api_key_name}"

  tags = {
    Environment = "${var.env}"
  }
}

# APIの使用量制限を設定するプラン
resource "aws_api_gateway_usage_plan" "usage_plan" {
  depends_on = [
    aws_api_gateway_stage.api_stage,
    aws_api_gateway_deployment.api_deployment,
    aws_api_gateway_rest_api.rest_api
  ]

  lifecycle {
    create_before_destroy = true
  }

  for_each = var.apis

  name = "${var.company_name}-${var.product_name}-${var.project_name}-${var.env}-${each.value.api_usage_plan_name}"

  # 使用プランに関連付けるAPIステージ
  api_stages {
    api_id = aws_api_gateway_rest_api.rest_api[each.key].id
    stage  = aws_api_gateway_stage.api_stage[each.key].stage_name
  }

  # クォータ設定（期間あたりの最大リクエスト数）
  quota_settings {
    limit  = each.value.usage_plan_quota_limit
    period = each.value.usage_plan_quota_period
  }

  # スロットリング設定（リクエストレート制限）
  throttle_settings {
    burst_limit = var.usage_plan_throttle_burst_limit
    rate_limit  = var.usage_plan_throttle_rate_limit
  }

  tags = {
    Environment = "${var.env}"
  }
}

# 作成したAPIキーを使用プランに関連付け
resource "aws_api_gateway_usage_plan_key" "usage_plan_key" {
  for_each = var.apis

  key_id        = aws_api_gateway_api_key.api_key[each.key].id
  key_type      = var.api_key_type
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan[each.key].id
}

# APIをLambdaに関連付け
# Lambda関数がAPI Gatewayからの呼び出しを受け入れるための許可設定
resource "aws_lambda_permission" "api_gateway" {
  for_each = var.apis

  statement_id  = var.lambda_permission_statement_id
  action        = var.lambda_permission_action
  function_name = var.lambda_function_names[each.value.lambda_name]
  principal     = var.lambda_permission_principal
  source_arn    = "${aws_api_gateway_rest_api.rest_api[each.key].execution_arn}/*/*"
}

# APIメソッドのログ記録と制限設定
resource "aws_api_gateway_method_settings" "api_method_settings" {
  for_each = var.apis

  rest_api_id = aws_api_gateway_rest_api.rest_api[each.key].id
  stage_name  = aws_api_gateway_stage.api_stage[each.key].stage_name
  method_path = "*/*"

  # CloudWatchログとスロットリング設定
  settings {
    metrics_enabled        = var.cloudwatch_metrics_enabled
    logging_level          = var.cloudwatch_logging_level
    data_trace_enabled     = var.cloudwatch_data_trace_enabled
    throttling_burst_limit = var.usage_plan_throttle_burst_limit
    throttling_rate_limit  = var.usage_plan_throttle_rate_limit
  }
}