data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_s3_bucket" "existing_artifacts" {
  count  = var.create_artifact_bucket ? 0 : 1
  bucket = var.artifact_s3_bucket_id
}
