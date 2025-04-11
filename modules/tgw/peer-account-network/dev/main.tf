#####################################################################################
# peer_dev_networkの設定
# Tgwのルートテーブルに0.0.0.0/0の静的ルートを追加する必要がある
# NatゲートウェイがあるPublicSubnetからTgwへの戻りのルートを設定する必要がある（戻りのルートが必要だから）
#####################################################################################

# # アウトバウンド用VPC
# module "outbound_vpc" {
#   source = "../../vpc"
#   vpc    = var.vpc
# }

module "tgw" {
  depends_on  = [module.outbound_vpc]
  source      = "terraform-aws-modules/transit-gateway/aws"
  for_each    = { for k, v in var.peer_dev_network : k => v }
  name        = each.key
  description = each.value.description
  # 共有アタッチメントの自動承認を有効化
  enable_auto_accept_shared_attachments = true
  amazon_side_asn                       = 65000

  # VPCアタッチメント設定
  vpc_attachments = {
    # アウトバウンドVPCへの接続設定
    outbound-vpc = {
      vpc_id      = module.outbound_vpc.vpc_id             # 接続先VPC ID
      subnet_ids  = module.outbound_vpc.private_subnet_ids # 接続先サブネットIDs
      dns_support = true                                   # DNS解決サポートを有効化

      # デフォルトルートテーブル関連の設定
      transit_gateway_default_route_table_association = true
      transit_gateway_default_route_table_propagation = true

      # TGWルート設定
      tgw_routes = [
        {
          destination_cidr_block = "0.0.0.0/0"
        }
      ]
    },
  }
  # 外部プリンシパルへの共有を許可
  ram_allow_external_principals = true
  # リソース共有先のプリンシパル（AWSアカウントなど）
  ram_principals = each.value.ram_principals
}

#####################################################################################
# 各メンバーアカウントの設定
# provider情報はfor_eachできない為複数のmdduleを作成する必要がある
#####################################################################################

module "tgw_peer" {
  source = "terraform-aws-modules/transit-gateway/aws"

  # ピアアカウント用のプロバイダー設定
  providers = {
    aws = aws.peer
  }

  # TGWの基本設定
  name        = "${local.name}-peer"
  description = "peerアカウント用のvpcアタッチメントを作成"

  # TGW作成と共有の設定
  create_tgw = false # 新規TGWを作成しない
  share_tgw  = false # TGWを共有しない
  # 共有アタッチメントの自動承認を有効化
  enable_auto_accept_shared_attachments = true

  # VPCアタッチメント設定
  vpc_attachments = {
    inbound-vpc = {
      tgw_id      = module.tgw["peer-account-dev"].ec2_transit_gateway_id # 接続先TGW ID
      vpc_id      = var.peer_dev_network.peer_vpc_id                      # ピアVPC ID
      subnet_ids  = var.peer_dev_network.peer_subnet_ids                  # ピアサブネットIDs
      dns_support = true                                                  # DNS解決サポートを有効化

      # ルーティング設定
      vpc_route_table_ids  = var.peer_dev_network.peer_route_table_ids # ピアVPCのPrivateルートテーブルIDs
      tgw_destination_cidr = "0.0.0.0/0"                               # 全ての宛先をtgwにルーティング
    }
  }
}

module "tgw_peer2" {
  source = "terraform-aws-modules/transit-gateway/aws"

  # ピアアカウント用のプロバイダー設定
  providers = {
    aws = aws.peer2
  }

  # TGWの基本設定
  name        = "${local.name}-peer"
  description = "peerアカウント用のvpcアタッチメントを作成"

  # TGW作成と共有の設定
  create_tgw = false # 新規TGWを作成しない
  share_tgw  = false # TGWを共有しない
  # 共有アタッチメントの自動承認を有効化
  enable_auto_accept_shared_attachments = true

  # VPCアタッチメント設定
  vpc_attachments = {
    inbound-vpc = {
      tgw_id      = module.tgw["peer-account-dev"].ec2_transit_gateway_id # 接続先TGW ID
      vpc_id      = var.peer2_dev_network.peer_vpc_id                     # ピアVPC ID
      subnet_ids  = var.peer2_dev_network.peer_subnet_ids                 # ピアサブネットIDs
      dns_support = true                                                  # DNS解決サポートを有効化

      # ルーティング設定
      vpc_route_table_ids  = var.peer2_dev_network.peer_route_table_ids # ピアVPCのPrivateルートテーブルIDs
      tgw_destination_cidr = "0.0.0.0/0"                                # 全ての宛先をtgwにルーティング
    }
  }
}

# module "tgw_peer3" {
#   source = "terraform-aws-modules/transit-gateway/aws"

#   # ピアアカウント用のプロバイダー設定
#   providers = {
#     aws = aws.peer3
#   }

#   # TGWの基本設定
#   name        = "${local.name}-peer"
#   description = "peerアカウント用のvpcアタッチメントを作成"

#   # TGW作成と共有の設定
#   create_tgw = false # 新規TGWを作成しない
#   share_tgw  = false # TGWを共有しない
#   # 共有アタッチメントの自動承認を有効化
#   enable_auto_accept_shared_attachments = true

#   # VPCアタッチメント設定
#   vpc_attachments = {
#     inbound-vpc = {
#       tgw_id      = module.tgw["peer-account-dev"].ec2_transit_gateway_id # 接続先TGW ID
#       vpc_id      = var.peer3_dev_network.peer_vpc_id                       # ピアVPC ID
#       subnet_ids  = var.peer3_dev_network.peer_subnet_ids                   # ピアサブネットIDs
#       dns_support = true                                                    # DNS解決サポートを有効化

#       # ルーティング設定
#       vpc_route_table_ids  = var.peer3_dev_network.peer_route_table_ids # ピアVPCのPrivateルートテーブルIDs
#       tgw_destination_cidr = "0.0.0.0/0"                                # 全ての宛先をtgwにルーティング
#     }
#   }
# }
