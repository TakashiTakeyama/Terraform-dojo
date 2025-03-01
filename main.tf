# SSM経由でEC2インスタンスを管理するためのモジュール
# VPC、WorkSpaces、SSM、ユーザーデータ、AMIの設定を行う
module "ssm_ec2" {
  source = "./modules/ssm-ec2"

  vpc_name        = var.vpc_name
  workspaces_name = var.workspaces_name
  ssm_ec2         = var.ssm_ec2
  user_data       = var.user_data
  ami_name        = var.ami_name
}

# KMSキーを作成・管理するためのモジュール
# 指定したIAMユーザーに管理者権限を付与し、エイリアスを設定
module "kms" {
  source = "./modules/kms"

  key_administrators = var.key_administrators
  aliases            = var.aliases
}

# IAMユーザーを作成するためのモジュール
# 指定した名前でユーザーを作成し、指定したポリシーをアタッチ
module "iam_user" {
  source = "./modules/iam"

  user_name               = var.iam_user_name
  create_access_key       = var.create_access_key
  create_login_profile    = var.create_login_profile
  password_reset_required = var.password_reset_required
  force_destroy           = var.force_destroy
  policy_arns             = var.iam_policy_arns
}

