locals {
  # IPAMプール設定の変換
  pool_configurations = {
    for pool in var.pools : pool.key => {
      description = pool.description # プールの説明
      cidr        = pool.cidr        # プールのCIDR範囲
      locale      = pool.locale      # プールのリージョン
      # サブプールの設定（存在する場合）
      sub_pools = pool.sub_pools != null ? {
        for sub_pool in pool.sub_pools : sub_pool.key => {
          name                     = sub_pool.name                     # サブプールの名前
          cidr                     = sub_pool.cidr                     # サブプールのCIDR範囲
          ram_share_principals     = sub_pool.ram_share_principals     # RAM共有先のプリンシパル
          allocation_resource_tags = sub_pool.allocation_resource_tags # リソース割り当て用タグ
        }
      } : {}
    }
  }
}