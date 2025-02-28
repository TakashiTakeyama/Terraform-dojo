# KMSキーを作成するモジュール
# key_administratorsで指定したIAMユーザーにキーの管理権限を付与
# aliasesで指定した名前でエイリアスを作成
module "kms" {
  source             = "terraform-aws-modules/kms/aws"
  description        = ""
  key_usage          = "ENCRYPT_DECRYPT" # 暗号化と復号化に使用
  key_administrators = var.key_administrators
  aliases            = var.aliases
}
