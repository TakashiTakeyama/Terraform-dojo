# Transit Gateway モジュール
# AWS アカウント間で共有するための Transit Gateway を作成します
module "tgw" {
  source  = "terraform-aws-modules/transit-gateway/aws"
  version = "~> 2.0"

  # Transit Gateway の基本設定
  name        = var.tgw_name # TGW の名前（変数から取得）
  description = "My TGW shared with several other AWS accounts"

  # 共有アタッチメントの自動承認を有効化
  enable_auto_accept_shared_attachments = true

  # VPC アタッチメント設定
  vpc_attachments = {
    vpc = {
      vpc_id       = module.vpc.vpc_id          # 接続する VPC の ID
      subnet_ids   = module.vpc.private_subnets # 接続するサブネット
      dns_support  = true                       # DNS サポートを有効化
      ipv6_support = true                       # IPv6 サポートを有効化

      # Transit Gateway のルート設定
      tgw_routes = [
        {
          destination_cidr_block = "30.0.0.0/16" # 宛先 CIDR ブロック
        },
        {
          blackhole              = true          # ブラックホールルート（トラフィックを破棄）
          destination_cidr_block = "40.0.0.0/20" # 宛先 CIDR ブロック
        }
      ]
    }
  }

  # RAM（Resource Access Manager）設定
  ram_allow_external_principals = true               # 外部プリンシパルへの共有を許可
  ram_principals                = var.ram_principals # 共有先の AWS アカウント ID
}

# VPC モジュール
# Transit Gateway に接続するための VPC を作成します
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  # VPC の基本設定
  name = var.vpc_name

  # CIDR ブロック設定
  cidr = var.vpc_cidr

  # アベイラビリティゾーンとサブネット設定
  azs             = data.aws_availability_zones.available.names
  private_subnets = var.private_subnets

  # IPv6 設定
  enable_ipv6                                    = true      # IPv6 を有効化
  private_subnet_assign_ipv6_address_on_creation = true      # サブネット作成時に IPv6 アドレスを割り当て
  private_subnet_ipv6_prefixes                   = [0, 1, 2] # IPv6 プレフィックス
}
