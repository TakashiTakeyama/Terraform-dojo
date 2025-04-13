# AWSのIPアドレス管理（IPAM）リソースを作成
# top_cidrは最上位のIPアドレス範囲を定義し、その下に複数のプールを構成
module "ipam" {
  source              = "aws-ia/ipam/aws"
  top_cidr            = ["10.0.0.0/8"]            # 最上位のCIDRブロック
  top_name            = "top_pool"                # 最上位プールの名前
  pool_configurations = local.pool_configurations # サブプール設定
}