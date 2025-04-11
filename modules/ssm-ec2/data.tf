# VPC情報を取得するデータソース
# 指定されたタグ名でVPCを検索
data "aws_vpc" "main_vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# Amazon Linux 2023 AMIを取得するデータソース
# 最新のAMIを取得し、指定された名前パターンでフィルタリング
data "aws_ami" "amazon_linux_23" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [var.ami_name]
  }
}