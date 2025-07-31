locals {
  # プライベートサブネットのIDリスト（VPC内のLambda配置用）
  private_subnets = data.aws_subnets.private.ids

  # プライベートサブネットのCIDRブロック一覧（ネットワーク制御やセキュリティグループ設定用）
  private_subnet_cidrs = [
    for s in data.aws_subnet.private : s.cidr_block
  ]

  # OpenAPI仕様書をテンプレート化（API Gateway用）
  api_spec = templatefile("${path.module}/../api-specification/llm-batch.yml", {
    region  = data.aws_region.current.region
    stage   = var.environment_name
    vpce_id = aws_vpc_endpoint.llm_batch_api_ep.id
    # lambda_invoke_arn = module.lambda["llm_batch_preparer"].qualified_arn
    lambda_invoke_arn = module.lambda["llm_batch_preparer"].function_arn
  })

  # Lambda関数の設定を定義（機能別最適化）
  lambda_functions = {
    # バッチ登録・状態取得API用Lambda
    llm_batch_preparer = {
      handler         = "llm_batch_preparer.handler" # エントリポイント
      timeout         = 30                           # API処理は短時間
      memory_size     = 256                          # 軽量な処理
      api_integration = true                         # API Gatewayと連携
      sqs_trigger     = false                        # SQSトリガーなし
      sqs_batch_size  = null                         # SQS未使用
      python_scripts = [
        "llm_batch_preparer.py",
        "common/__init__.py",
        "common/aws_clients.py",
        "common/response_utils.py",
        "common/batch_status.py",
      ]
      environment_variables = {
        DYNAMODB_TABLE_NAME   = aws_dynamodb_table.llm_batch_table.name                                                                                     # DynamoDBテーブル名
        SQS_QUEUE_URL         = aws_sqs_queue.llm_batch_queue.url                                                                                           # SQSキューURL
        ANTHROPIC_SECRET_NAME = data.aws_secretsmanager_secret_version.anthropic_api_key.secret_string                                                      # Anthropic APIキー
        ALLOWED_ORIGINS       = var.environment_name == "production" ? "https://app.hoge.com" : "https://localhost:3000,https://staging.hoge.com" # CORS許可
      }
    }

    # バッチ送信・Anthropic API連携用Lambda
    llm_batch_sender = {
      handler         = "llm_batch_sender.handler" # エントリポイント
      timeout         = 300                        # バッチ送信は時間がかかる
      memory_size     = 1024                       # Anthropic API処理で大きめ
      api_integration = false                      # API Gatewayと連携しない
      sqs_trigger     = true                       # SQSトリガーあり
      sqs_batch_size  = 1                          # 1件ずつ処理（FIFOキュー対応）
      python_scripts = [
        "llm_batch_sender.py",
        "common/__init__.py",
        "common/aws_clients.py",
        "common/response_utils.py",
        "common/batch_status.py",
      ]
      environment_variables = {
        DYNAMODB_TABLE_NAME   = aws_dynamodb_table.llm_batch_table.name                                # DynamoDBテーブル名
        LLM_PIPELINE_BUCKET   = aws_s3_bucket.llm_batch_bucket.id                                      # S3バケット名
        ANTHROPIC_SECRET_NAME = data.aws_secretsmanager_secret_version.anthropic_api_key.secret_string # Anthropic APIキー
      }
    }

    # バッチ結果収集・状態監視用Lambda
    llm_batch_collector = {
      handler             = "llm_batch_collector.handler" # エントリポイント
      timeout             = 300                           # Anthropic API呼び出しのため時間を増加
      memory_size         = 1024                          # Anthropic API処理でメモリを増加
      api_integration     = false                         # API Gatewayと連携しない
      sqs_trigger         = false                         # SQSトリガーなし（EventBridge定期実行のみ）
      sqs_batch_size      = null                          # SQS使用しないためnull
      eventbridge_trigger = true                          # EventBridge定期実行のみ
      python_scripts = [
        "llm_batch_collector.py",
        "common/__init__.py",
        "common/aws_clients.py",
        "common/response_utils.py",
        "common/batch_status.py",
      ]
      environment_variables = {
        DYNAMODB_TABLE_NAME   = aws_dynamodb_table.llm_batch_table.name                                # DynamoDBテーブル名
        LLM_PIPELINE_BUCKET   = aws_s3_bucket.llm_batch_bucket.id                                      # S3バケット名
        ANTHROPIC_SECRET_NAME = data.aws_secretsmanager_secret_version.anthropic_api_key.secret_string # Anthropic APIキー
      }
    }
  }

  # eventbridge_trigger = true の Lambda だけを抽出
  lambda_functions_with_eventbridge = {
    for k, v in local.lambda_functions : k => v
    if try(v.eventbridge_trigger, false)
  }
}
