locals {
  # リストが単純な文字列のリストであれば、`toset(var.example_list)` のようにセットに変換すれば、各要素を `each.value` で利用できます。  
  # リストがオブジェクトの場合、直接 for_each に渡すことはできません。  
  # なぜなら、オブジェクトのリストでは各要素に一意なキーが存在しないため、Terraform は反復処理のキー（each.key）を割り当てることができないからです。
  # for_each = var.instances
  # instance_class = each.value.instance_class
  # identifier = each.value.identifier

  # 正しい使い方の例（オブジェクトのリストの場合）
  # オブジェクトのリストを直接 for_each で使うことはできないので、通常は for 式でマップに変換します。
  sample         = { for k, v in var.instances : k => v }
  instance_class = each.value.instance_class
  identifier     = each.value.identifier

  hoge = { for v in var.instances : v.name => {
    name           = v.name
    instance_class = v.instance_class
    identifier     = v.identifier
    }
  }

  # DBのエンドポイントを取得サンプル
  db_endpoints = flatten([
    [
      for db_key, db_val in module.aurora : [
        {
          alias       = "${db_key}-secret-arn"
          name        = "/hoge/${db_key}/secret_arn"
          value       = db_val.cluster.cluster_master_user_secret[0].secret_arn
          secure_type = true
        }
      ]
    ],
    [
      for db_key, db_val in module.aurora : [
        {
          alias       = "${db_key}-writer"
          name        = "/hoge/${db_key}/endpoint"
          value       = db_val.cluster.cluster_endpoint
          secure_type = true
        },
        {
          alias       = "${db_key}-read-only"
          name        = "/hoge/${db_key}/reader_endpoint"
          value       = db_val.cluster.cluster_reader_endpoint
          secure_type = true
        }
      ]
    ],
    [
      for db_key, db_val in module.memory_db : [
        {
          alias       = "${db_key}"
          name        = "/hoge/${db_key}/endpoint"
          value       = "${db_val.aws_memorydb_cluster.cluster_endpoint[0].address}:${db_val.aws_memorydb_cluster.cluster_endpoint[0].port}"
          secure_type = true
        },
      ]
    ],
  ])
}
