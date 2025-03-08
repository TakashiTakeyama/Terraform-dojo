# S3バケットを作成するモジュール
# terraform-aws-modules/s3-bucket/aws モジュールを使用
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket        = var.bucket_name   # バケット名
  force_destroy = var.force_destroy # 強制削除の有無

  # ACLを無効化（現代的アプローチ）
  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  # パブリックアクセスをブロック（セキュリティレイヤー）
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # 詳細なアクセス制御はバケットポリシーで実装
  attach_policy = true
  policy        = var.bucket_policy

  # バージョニング設定
  versioning = {
    enabled = var.versioning_enabled
  }

  # サーバーサイド暗号化の設定
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = var.kms_key_id
      }
      bucket_key_enabled = true # S3 Bucket Keyを有効化してコスト削減
    }
  }

  # ライフサイクルルールの設定
  lifecycle_rule = var.lifecycle_rules

  # オブジェクトロックの設定
  object_lock_enabled = true
  object_lock_configuration = {
    rule = {
      default_retention = {
        mode = "COMPLIANCE"
        days = 30
      }
    }
  }

  # リクエスタ支払いの有効化
  request_payer = "Requester"

  # インテリジェント階層化の設定
  intelligent_tiering = {
    status = "Enabled"
    filter = {
      prefix = "data/"
      tags = {
        Environment = "dev"
      }
    }
    tiering = {
      archive_access_tier = {
        days = 90
      }
      deep_archive_access_tier = {
        days = 180
      }
    }
  }
}

resource "aws_s3_access_point" "example" {
  name   = "example-access-point"
  bucket = module.s3_bucket.s3_bucket_id

  # アクセスポイント用のポリシー
  policy = jsonencode({
    // ポリシー内容
  })
}
