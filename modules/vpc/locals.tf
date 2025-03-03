locals {
  # 利用可能なAZのリストを作成
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}