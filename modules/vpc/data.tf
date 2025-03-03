# 現在のリージョンを取得
data "aws_region" "current" {}

# 利用可能なAZを取得
data "aws_availability_zones" "available" {
  state = "available"
}
