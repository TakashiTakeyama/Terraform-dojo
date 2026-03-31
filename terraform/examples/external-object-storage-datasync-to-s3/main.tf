# Sample: DataSync between two S3 buckets (replace source location for external S3-compatible storage; see README).
locals {
  name_prefix = "${var.stage}-${var.project}"
}

resource "aws_s3_bucket" "source" {
  bucket = "${local.name_prefix}-source"
}

resource "aws_s3_bucket" "destination" {
  bucket = "${local.name_prefix}-destination"
}

resource "aws_s3_bucket_public_access_block" "source" {
  bucket                  = aws_s3_bucket.source.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "destination" {
  bucket                  = aws_s3_bucket.destination.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "datasync_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["datasync.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "datasync_source" {
  name               = "${local.name_prefix}-datasync-src"
  assume_role_policy = data.aws_iam_policy_document.datasync_assume.json
}

resource "aws_iam_role" "datasync_destination" {
  name               = "${local.name_prefix}-datasync-dst"
  assume_role_policy = data.aws_iam_policy_document.datasync_assume.json
}

data "aws_iam_policy_document" "datasync_source_s3" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = [
      aws_s3_bucket.source.arn,
      "${aws_s3_bucket.source.arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "datasync_destination_s3" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = [
      aws_s3_bucket.destination.arn,
      "${aws_s3_bucket.destination.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "datasync_source" {
  name   = "s3-read"
  role   = aws_iam_role.datasync_source.id
  policy = data.aws_iam_policy_document.datasync_source_s3.json
}

resource "aws_iam_role_policy" "datasync_destination" {
  name   = "s3-write"
  role   = aws_iam_role.datasync_destination.id
  policy = data.aws_iam_policy_document.datasync_destination_s3.json
}

resource "aws_datasync_location_s3" "source" {
  s3_bucket_arn = aws_s3_bucket.source.arn
  subdirectory  = ""

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_source.arn
  }
}

resource "aws_datasync_location_s3" "destination" {
  s3_bucket_arn = aws_s3_bucket.destination.arn
  subdirectory  = ""

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_destination.arn
  }
}

resource "aws_datasync_task" "copy" {
  count = var.enable_task ? 1 : 0

  name                     = "${local.name_prefix}-copy"
  source_location_arn      = aws_datasync_location_s3.source.arn
  destination_location_arn = aws_datasync_location_s3.destination.arn

  options {
    verify_mode = "ONLY_FILES_TRANSFERRED"
  }
}
