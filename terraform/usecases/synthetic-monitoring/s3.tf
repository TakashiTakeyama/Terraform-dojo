resource "aws_s3_bucket" "canary_artifacts" {
  bucket = "${local.name_prefix}-synthetics-artifacts"
}

resource "aws_s3_bucket_public_access_block" "canary_artifacts" {
  bucket = aws_s3_bucket.canary_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "canary_artifacts" {
  bucket = aws_s3_bucket.canary_artifacts.id

  rule {
    id     = "expire-old-results"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}
