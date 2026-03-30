data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_s3_bucket" "canary_deployments" {
  bucket = "${local.name_prefix}-synthetics-deployments"
}

# synthetic-monitoring-pipeline の Build ステージが S3 にアップロードした zip の
# 最新バージョンを取得し、canary.tf の s3_version に渡す。
# バージョニング有効バケットのため、アップロードごとに version_id が変わり
# terraform plan で差分として検知される。
#
# 前提: synthetic-monitoring-pipeline スタックが先に apply 済みであること。
# 未適用だと S3 オブジェクトが存在せずエラーになる。
data "aws_s3_object" "web_canary_code" {
  bucket = data.aws_s3_bucket.canary_deployments.bucket
  key    = "web-scenario/canary.zip"
}

data "aws_s3_object" "api_canary_code" {
  bucket = data.aws_s3_bucket.canary_deployments.bucket
  key    = "api-scenario/canary.zip"
}
