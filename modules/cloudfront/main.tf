# CloudFrontディストリビューションの作成
# CloudFrontを使用してコンテンツ配信を最適化し、エッジロケーションを活用してレイテンシーを削減
module "cdn" {
  source = "terraform-aws-modules/cloudfront/aws"

  # カスタムドメインの設定
  # 独自ドメインを使用してCloudFrontディストリビューションにアクセス可能にする
  aliases = var.aliases

  comment             = var.comment         # ディストリビューションの説明
  enabled             = var.enabled         # ディストリビューションの有効/無効
  is_ipv6_enabled     = var.is_ipv6_enabled # IPv6サポートの有効化
  price_class         = var.price_class     # 使用するエッジロケーションの範囲を指定
  retain_on_delete    = false               # 削除時にディストリビューションを保持しない
  wait_for_deployment = false               # デプロイ完了を待たない

  # S3バケットアクセス用のOrigin Access Identity(OAI)を作成
  # S3バケットへのアクセスを制限し、CloudFrontからのみアクセス可能にする
  create_origin_access_identity = true
  origin_access_identities = {
    s3_bucket_one = var.origin_access_identities
  }

  # アクセスログの設定
  # CloudFrontのアクセスログをS3バケットに保存
  logging_config = {
    bucket = var.logging_config_bucket
  }

  # オリジンの設定
  # コンテンツの配信元となるオリジンサーバーの設定
  origin = {
    # カスタムオリジンの設定
    # 独自のWebサーバーをオリジンとして使用
    something = {
      domain_name = "something.example.com"
      custom_origin_config = {
        http_port              = 80                              # HTTPポート
        https_port             = 443                             # HTTPSポート
        origin_protocol_policy = "match-viewer"                  # ビューワーのプロトコルに合わせる
        origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"] # 使用可能なSSL/TLSプロトコル
      }
    }

    # S3バケットオリジンの設定
    # S3バケットをオリジンとして使用
    s3_one = {
      domain_name = var.s3_origin_config_domain_name
      s3_origin_config = {
        origin_access_identity = "s3_bucket_one" # 上記で作成したOAIを使用
      }
    }
  }

  # デフォルトのキャッシュ動作設定
  # すべてのリクエストに適用されるデフォルトのキャッシュ設定
  default_cache_behavior = {
    target_origin_id       = "something" # デフォルトで使用するオリジン
    viewer_protocol_policy = "allow-all" # HTTPとHTTPSの両方を許可

    allowed_methods = ["GET", "HEAD", "OPTIONS"] # 許可するHTTPメソッド
    cached_methods  = ["GET", "HEAD"]            # キャッシュするHTTPメソッド
    compress        = true                       # コンテンツの圧縮を有効化
    query_string    = true                       # クエリ文字列をキャッシュキーに含める
  }

  # パスパターンに基づく追加のキャッシュ動作設定
  # 特定のパスパターンに対して個別のキャッシュ設定を適用
  ordered_cache_behavior = [
    {
      path_pattern           = "/static/*"         # 静的コンテンツのパスパターン
      target_origin_id       = "s3_one"            # S3バケットをオリジンとして使用
      viewer_protocol_policy = "redirect-to-https" # HTTPSへリダイレクト

      allowed_methods = ["GET", "HEAD", "OPTIONS"] # 許可するHTTPメソッド
      cached_methods  = ["GET", "HEAD"]            # キャッシュするHTTPメソッド
      compress        = true                       # コンテンツの圧縮を有効化
      query_string    = true                       # クエリ文字列をキャッシュキーに含める
    }
  ]

  # SSL/TLS証明書の設定
  # HTTPS通信に使用するSSL/TLS証明書の設定
  viewer_certificate = {
    acm_certificate_arn = var.viewer_certificate_acm_certificate_arn # ACM証明書のARN
    ssl_support_method  = "sni-only"                                 # Server Name Indication(SNI)を使用
  }
}