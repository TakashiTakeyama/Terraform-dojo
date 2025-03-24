# API Gatewayモジュールの定義
# HTTP APIタイプのAPI Gatewayを作成します
module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  name          = var.name        # API Gatewayの名前
  description   = var.description # API Gatewayの説明
  protocol_type = "HTTP"          # プロトコルタイプはHTTP

  # CORSの設定
  # クロスオリジンリクエストを許可するための設定
  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"] # 許可するヘッダー
    allow_methods = ["*"]                                                                                                    # すべてのHTTPメソッドを許可
    allow_origins = ["*"]                                                                                                    # すべてのオリジンからのリクエストを許可
  }

  # カスタムドメイン設定
  domain_name = var.domain_name

  # アクセスログの設定
  # APIへのリクエストのログを記録するための設定
  stage_access_log_settings = {
    create_log_group            = true # ロググループを作成する
    log_group_retention_in_days = 7    # ログの保持期間は7日間
    format = jsonencode({              # ログのフォーマット（JSON形式）
      context = {
        domainName              = "$context.domainName"              # ドメイン名
        integrationErrorMessage = "$context.integrationErrorMessage" # 統合エラーメッセージ
        protocol                = "$context.protocol"                # プロトコル
        requestId               = "$context.requestId"               # リクエストID
        requestTime             = "$context.requestTime"             # リクエスト時間
        responseLength          = "$context.responseLength"          # レスポンスの長さ
        routeKey                = "$context.routeKey"                # ルートキー
        stage                   = "$context.stage"                   # ステージ
        status                  = "$context.status"                  # ステータス
        error = {
          message      = "$context.error.message"      # エラーメッセージ
          responseType = "$context.error.responseType" # レスポンスタイプ
        }
        identity = {
          sourceIP = "$context.identity.sourceIp" # 送信元IP
        }
        integration = {
          error             = "$context.integration.error"             # 統合エラー
          integrationStatus = "$context.integration.integrationStatus" # 統合ステータス
        }
      }
    })
  }

  # 認証設定
  # JWTを使用した認証の設定
  authorizers = {
    "lambda-auth" = {
      authorizer_type  = "JWT"                             # 認証タイプはJWT
      identity_sources = ["$request.header.Authorization"] # 認証情報のソース
      name             = "lambda-auth"                     # 認証名
      jwt_configuration = {
        audience = ["d6a38afd-45d6-4874-d1aa-3c5c558aqcc2"]                        # 対象のオーディエンス
        issuer   = "https://sts.windows.net/aaee026e-8f37-410e-8869-72d9154873e4/" # トークン発行者
      }
    }
  }

  # ルートと統合設定
  # APIのエンドポイントとバックエンドの統合設定
  routes = {
    # POSTメソッドのルート設定
    "POST /" = {
      integration = {
        uri                    = var.lambda_function_arn # Lambda関数のURI
        payload_format_version = "2.0"                   # ペイロードフォーマットバージョン
        timeout_milliseconds   = 12000                   # タイムアウト設定（12秒）
      }
    }

    # 認証付きGETメソッドのルート設定
    "GET /some-route-with-authorizer" = {
      authorizer_key = "azure" # 使用する認証設定

      integration = {
        type = "HTTP_PROXY" # 統合タイプはHTTP_PROXY
        uri  = "some url"   # バックエンドのURI
      }
    }

    # デフォルトルートの設定
    "$default" = {
      integration = {
        uri = var.lambda_function_arn # デフォルトのLambda関数
      }
    }
  }
}