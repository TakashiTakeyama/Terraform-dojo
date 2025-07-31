########################################################
# API Gateway
########################################################

# API Gateway用セキュリティグループ
resource "aws_security_group" "api_gw_private" {
  name        = "${var.resource_prefix}llm-batch-api-sg"
  description = "Allow only private-subnet CIDRs to reach API Gateway endpoint"
  vpc_id      = data.aws_vpc.main_vpc.id

  ingress {
    description = "HTTPS from private subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = local.private_subnet_cidrs
  }

  tags = var.tags
}

# VPCエンドポイント（API Gateway用）を作成
resource "aws_vpc_endpoint" "llm_batch_api_ep" {
  private_dns_enabled = false
  security_group_ids  = [aws_security_group.api_gw_private.id]
  service_name        = "com.amazonaws.${data.aws_region.current.region}.execute-api"
  subnet_ids          = local.private_subnets
  vpc_endpoint_type   = "Interface"
  vpc_id              = data.aws_vpc.main_vpc.id

  tags = var.tags
}

# REST API Gateway
resource "aws_api_gateway_rest_api" "llm_batch_api" {
  body              = local.api_spec
  name              = "${var.resource_prefix}llm-batch-api"
  put_rest_api_mode = "merge" # OpenAPI仕様書の変更で再作成ではなく更新

  # プライベートエンドポイントとして設定し、VPCエンドポイントIDを指定
  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = [aws_vpc_endpoint.llm_batch_api_ep.id]
  }

  tags = var.tags
}

# API Gatewayのデプロイメントを作成
resource "aws_api_gateway_deployment" "llm_batch_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.llm_batch_api.id

  # OpenAPI仕様の変更時に再デプロイをトリガー
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.llm_batch_api.body))
  }

  lifecycle {
    create_before_destroy = true # 破棄前に新規作成
  }
}

# API Gatewayのステージを作成（ログ設定は削除）
resource "aws_api_gateway_stage" "llm_batch_api_stage" {
  deployment_id = aws_api_gateway_deployment.llm_batch_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.llm_batch_api.id
  stage_name    = var.environment_name

  # CloudWatch 連携（アカウント全体設定）を使わないため、アクセスログ設定は行いません
  xray_tracing_enabled = false

  tags = var.tags
}

# API Gatewayのリソースポリシー（VPCEからのみアクセス可能）
resource "aws_api_gateway_rest_api_policy" "llm_batch_api_policy" {
  rest_api_id = aws_api_gateway_rest_api.llm_batch_api.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = "*",
      Action    = "execute-api:Invoke",
      Resource  = "${aws_api_gateway_rest_api.llm_batch_api.execution_arn}/*/*/*",
      Condition = {
        StringEquals = {
          "aws:SourceVpce" = aws_vpc_endpoint.llm_batch_api_ep.id
        }
      }
    }]
  })
}

########################################################
# Lambda
########################################################

# LambdaからSQSへのアクセス許可
resource "aws_iam_role_policy" "lambda_sqs_policy" {
  name = "${var.resource_prefix}lambda-sqs-policy"
  role = "dev-llm_pipeline_lambda_iam_role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility",
          "sqs:SendMessage"
        ]
        Resource = [
          aws_sqs_queue.llm_batch_queue.arn,
          aws_sqs_queue.llm_batch_dlq.arn,
        ]
      }
    ]
  })
}

# LambdaからDynamoDBへのアクセス許可
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = "${var.resource_prefix}lambda-dynamodb-policy"
  role = "dev-llm_pipeline_lambda_iam_role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:*"
        ]
        Resource = [
          aws_dynamodb_table.llm_batch_table.arn
        ]
      }
    ]
  })
}

# Lambdaパッケージ(zip)を作成するモジュール
module "zipper" {
  for_each = local.lambda_functions
  source   = "../../base/zipper"

  python_runtime = var.python_runtime
  python_scripts = each.value.python_scripts
  source_dir     = "${path.module}/lambdas"
  zip_file       = "${var.resource_prefix}${each.key}-llm-batch-lambda.zip"
}

# Lambda関数を動的に生成
module "lambda" {
  depends_on = [module.zipper, aws_iam_role_policy.lambda_sqs_policy]
  for_each   = local.lambda_functions
  source     = "../../base/lambda"

  environment_name = var.environment_name
  function_name    = "${var.resource_prefix}llm-batch-${replace(each.key, "_", "-")}"
  filename         = module.zipper[each.key].zip_path
  source_code_hash = module.zipper[each.key].zip_hash
  runtime          = var.python_runtime
  role_arn         = var.lambda_role_arn
  handler          = each.value.handler
  timeout          = each.value.timeout
  memory_size      = each.value.memory_size

  environment_variables = merge(
    each.value.environment_variables,
    {
      # 共通環境変数
      ENVIRONMENT = var.environment_name
      LOG_LEVEL   = var.environment_name == "production" ? "INFO" : "DEBUG"
    }
  )
}

# Lambda関数からAPI Gatewayへの呼び出し許可
resource "aws_lambda_permission" "api_gateway_invoke" {
  for_each = {
    for k, v in local.lambda_functions : k => v
    if v.api_integration
  }

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda[each.key].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.llm_batch_api.execution_arn}/*/*/*"
}

# Lambda関数用CloudWatchロググループ
resource "aws_cloudwatch_log_group" "lambda_logs" {
  for_each = local.lambda_functions

  name              = "/aws/lambda/${module.lambda[each.key].function_name}"
  retention_in_days = var.environment_name == "production" ? 30 : 7

  tags = var.tags
}

# Lambdaデプロイ後のクリーンアップ処理
resource "null_resource" "post_deployment_cleanup" {
  depends_on = [module.lambda]
  for_each   = local.lambda_functions

  # Lambdaデプロイが完了したらトリガー
  triggers = {
    lambda_function_arn  = module.lambda[each.key].function_arn
    lambda_qualified_arn = module.lambda[each.key].qualified_arn
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOF
echo "Post-deployment cleanup start for: ${each.key}"

CLEANUP_SCRIPT=$(cat <<'CLEANUP_EOF'
${module.zipper[each.key].cleanup_command}
CLEANUP_EOF
)

eval "$CLEANUP_SCRIPT"

echo "Post-deployment cleanup done for: ${each.key}"
EOF
  }
}

########################################################
# DynamoDB
########################################################

# LLM batch用テーブル
resource "aws_dynamodb_table" "llm_batch_table" {
  name      = "${var.resource_prefix}llm-batch-table"
  hash_key  = "job_id"
  range_key = "batch_id"

  attribute {
    name = "job_id"
    type = "S"
  }
  attribute {
    name = "batch_id"
    type = "S"
  }

  # global_secondary_index {
  #   name            = "batch-id-index"
  #   hash_key        = "batch_id"
  #   projection_type = "ALL"
  # }

  # 本番環境ではオンデマンド、開発環境ではプロビジョンド
  billing_mode = var.environment_name == "production" ? "ON_DEMAND" : "PROVISIONED"
  # プロビジョンドモードの場合の設定
  read_capacity  = var.environment_name == "production" ? null : 5
  write_capacity = var.environment_name == "production" ? null : 5

  tags = var.tags
}

########################################################
# SQS
########################################################

# FIFO Queue
resource "aws_sqs_queue" "llm_batch_queue" {
  name                        = "${var.resource_prefix}llm-batch-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  message_retention_seconds   = 1209600 # 14 days
  visibility_timeout_seconds  = 1800    # 30 minutes 可視性タイムアウト（Lambda実行時間より長く設定）

  # リドライブポリシー（DLQへの転送設定）
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.llm_batch_dlq.arn
    maxReceiveCount     = 5
  })

  tags = var.tags
}

# Dead Letter Queue (FIFO)
resource "aws_sqs_queue" "llm_batch_dlq" {
  name                        = "${var.resource_prefix}llm-batch-dlq.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  message_retention_seconds   = 1209600 # 14 days

  tags = var.tags
}

# Lambda関数からSQSへのトリガー設定（FIFO対応）
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  for_each = {
    for k, v in local.lambda_functions : k => v
    if v.sqs_trigger
  }

  event_source_arn        = aws_sqs_queue.llm_batch_queue.arn
  function_name           = module.lambda[each.key].function_name
  batch_size              = each.value.sqs_batch_size
  function_response_types = ["ReportBatchItemFailures"] # エラーハンドリング（部分的失敗対応）

  scaling_config {
    maximum_concurrency = 10
  }
}

########################################################
# EventBridge
########################################################

# EventBridge定期実行ルール（collector用）
resource "aws_cloudwatch_event_rule" "batch_status_polling" {
  name                = "${var.resource_prefix}llm-batch-status-polling"
  description         = "Trigger batch status polling every 5 minutes"
  schedule_expression = "rate(5 minutes)"

  tags = var.tags
}

# EventBridgeターゲット（collector Lambda関数）
resource "aws_cloudwatch_event_target" "batch_collector_target" {
  for_each = local.lambda_functions_with_eventbridge

  rule      = aws_cloudwatch_event_rule.batch_status_polling.name
  target_id = "BatchCollectorTarget-${each.key}" # ルール内で一意に
  arn       = module.lambda[each.key].function_arn

  input = jsonencode({
    source      = "aws.events"
    detail-type = "Scheduled Event"
    detail = {
      trigger_type = "batch_status_polling"
      schedule     = "rate(5 minutes)"
    }
  })
}

# EventBridge → Lambda許可
resource "aws_lambda_permission" "eventbridge_invoke" {
  for_each = local.lambda_functions_with_eventbridge

  statement_id  = "AllowExecutionFromEventBridge-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda[each.key].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.batch_status_polling.arn
}

########################################################
# S3
########################################################

# LLMバッチ処理用S3バケット
resource "aws_s3_bucket" "llm_batch_bucket" {
  bucket = "${var.resource_prefix}llm-batch-storage"

  tags = var.tags
}

# # バケット暗号化
# resource "aws_s3_bucket_server_side_encryption_configuration" "llm_batch_bucket_encryption" {
#   bucket = aws_s3_bucket.llm_batch_bucket.id
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }

# # ライフサイクル管理
# resource "aws_s3_bucket_lifecycle_configuration" "llm_batch_bucket_lifecycle" {
#   bucket = aws_s3_bucket.llm_batch_bucket.id

#   rule {
#     id     = "rule-1"
#     status = "Enabled"

#     filter {
#       prefix = "llm-batch-data/"
#     }
#   }

#   rule {
#     id     = "batch_data_lifecycle"
#     status = "Enabled"
#     # 30日後にIA、90日後にGlacier、1年後に削除
#     transition {
#       days          = 30
#       storage_class = "STANDARD_IA"
#     }
#     transition {
#       days          = 90
#       storage_class = "GLACIER"
#     }
#     expiration {
#       days = 365
#     }

#     # 不完全なマルチパートアップロードの削除
#     abort_incomplete_multipart_upload {
#       days_after_initiation = 7
#     }
#   }
# }

########################################################
# CloudWatch Alarms
########################################################

# Lambda関数のエラー率アラーム
resource "aws_cloudwatch_metric_alarm" "lambda_error_rate" {
  for_each = local.lambda_functions

  alarm_name          = "${var.resource_prefix}${each.key}-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "This metric monitors lambda error rate"
  alarm_actions       = var.environment_name == "production" ? [aws_sns_topic.alerts[0].arn] : []

  dimensions = {
    FunctionName = module.lambda[each.key].function_name
  }

  tags = var.tags
}

# DynamoDB throttling アラーム
resource "aws_cloudwatch_metric_alarm" "dynamodb_throttles" {
  alarm_name          = "${var.resource_prefix}dynamodb-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "This metric monitors DynamoDB throttling"
  alarm_actions       = var.environment_name == "production" ? [aws_sns_topic.alerts[0].arn] : []

  dimensions = {
    TableName = aws_dynamodb_table.llm_batch_table.name
  }

  tags = var.tags
}

# SNS Topic for alerts (production only)
resource "aws_sns_topic" "alerts" {
  count = var.environment_name == "production" ? 1 : 0
  name  = "${var.resource_prefix}llm-batch-alerts"

  tags = var.tags
}
