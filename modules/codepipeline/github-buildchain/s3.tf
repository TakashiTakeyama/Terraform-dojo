resource "aws_s3_bucket" "pipeline_artifacts" {
  count = var.create_artifact_bucket ? 1 : 0

  bucket = coalesce(
    var.artifact_s3_bucket_name,
    "${data.aws_caller_identity.current.account_id}-${var.name_prefix}-pipeline-artifacts"
  )

  force_destroy = var.artifact_bucket_force_destroy

  tags = var.tags
}

resource "aws_s3_bucket_ownership_controls" "pipeline_artifacts" {
  count = var.create_artifact_bucket ? 1 : 0

  bucket = aws_s3_bucket.pipeline_artifacts[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "pipeline_artifacts" {
  count = var.create_artifact_bucket ? 1 : 0

  bucket = aws_s3_bucket.pipeline_artifacts[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "pipeline_artifacts" {
  count = var.create_artifact_bucket ? 1 : 0

  bucket = aws_s3_bucket.pipeline_artifacts[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline_artifacts" {
  count = var.create_artifact_bucket && var.artifact_store_kms_key_arn != null ? 1 : 0

  bucket = aws_s3_bucket.pipeline_artifacts[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.artifact_store_kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "pipeline_artifacts" {
  count = var.create_artifact_bucket && var.artifact_lifecycle_expiration_days > 0 ? 1 : 0

  bucket = aws_s3_bucket.pipeline_artifacts[0].id

  rule {
    id     = "expire-pipeline-artifacts"
    status = "Enabled"

    expiration {
      days = var.artifact_lifecycle_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.artifact_lifecycle_expiration_days
    }
  }
}
