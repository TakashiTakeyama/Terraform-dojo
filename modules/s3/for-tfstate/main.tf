module "tfstate_bucket" {
  source = "../basic" # 基本的なS3バケット設定を含むモジュールを使用

  bucket_name        = "tfstate-management-bucket" # tfstate管理用のS3バケット名
  force_destroy      = true                        # バケットの強制削除を許可
  versioning_enabled = true                        # バケットのバージョニングを有効化
  sse_enabled        = true                        # サーバーサイド暗号化を有効化

  bucket_policy = jsonencode({ # HTTPSアクセスのみを許可するバケットポリシー
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceTLSRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "arn:aws:s3:::tfstate-management-bucket",
          "arn:aws:s3:::tfstate-management-bucket/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" : "false"
          }
        }
      }
    ]
  })

  lifecycle_rules = [ # 古いバージョンを90日後に削除するライフサイクルルール
    {
      id      = "delete_old_versions"
      enabled = true
      noncurrent_version_expiration = {
        days = 90
      }
    }
  ]
}
