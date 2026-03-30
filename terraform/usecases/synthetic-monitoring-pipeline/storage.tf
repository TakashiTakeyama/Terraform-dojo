# CodePipeline がステージ間でデータを受け渡すための一時バケット。
# ビルド完了後は不要なため 7 日で自動削除。バージョニングは不要。
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "${local.name_prefix}-synthetics-pipeline-artifact"
}

resource "aws_s3_bucket_lifecycle_configuration" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  rule {
    id     = "DeleteRule"
    status = "Enabled"
    expiration {
      days = 7
    }
    filter {}
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Canary コード（zip）の保存先。terraform apply がここから zip を読み取る。
# バージョニング有効でロールバック可能。旧バージョンは 30 日で自動削除。
resource "aws_s3_bucket" "canary_deployments" {
  bucket = "${local.name_prefix}-synthetics-deployments"
}

resource "aws_s3_bucket_versioning" "canary_deployments" {
  bucket = aws_s3_bucket.canary_deployments.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "canary_deployments" {
  bucket = aws_s3_bucket.canary_deployments.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "canary_deployments" {
  bucket = aws_s3_bucket.canary_deployments.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# synthetic-monitoring スタックの data.aws_s3_object が初回から参照できるよう、
# バケット作成時にプレースホルダーを配置する。
# パイプライン実行後に実際の zip で上書きされ、以降 Terraform はこのリソースを変更しない。
resource "aws_s3_object" "web_canary_initial" {
  bucket  = aws_s3_bucket.canary_deployments.bucket
  key     = "web-scenario/canary.zip"
  content = ""

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_s3_object" "api_canary_initial" {
  bucket  = aws_s3_bucket.canary_deployments.bucket
  key     = "api-scenario/canary.zip"
  content = ""

  lifecycle {
    ignore_changes = all
  }
}

# バージョニングで蓄積される旧バージョンを 30 日で自動削除（最新版は保持される）
resource "aws_s3_bucket_lifecycle_configuration" "canary_deployments" {
  bucket = aws_s3_bucket.canary_deployments.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}
