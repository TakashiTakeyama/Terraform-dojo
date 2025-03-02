# SSM経由でEC2インスタンスを管理するためのモジュール
# VPC、WorkSpaces、SSM、ユーザーデータ、AMIの設定を行う
module "ssm_ec2" {
  source = "./modules/ssm-ec2"

  vpc_name        = var.vpc_name        # VPCの名前
  workspaces_name = var.workspaces_name # WorkSpacesの名前
  ssm_ec2         = var.ssm_ec2         # SSMの設定
  user_data       = var.user_data       # EC2起動時に実行するユーザーデータスクリプト
  ami_name        = var.ami_name        # 使用するAMIの名前
}

# KMSキーを作成・管理するためのモジュール
# 指定したIAMユーザーに管理者権限を付与し、エイリアスを設定
module "kms" {
  source = "./modules/kms"

  key_administrators = var.key_administrators # KMSキーの管理者権限を付与するIAMユーザーのリスト
  aliases            = var.aliases            # KMSキーに設定するエイリアスのリスト
}

# IAMユーザーを作成するためのモジュール
# 指定した名前でユーザーを作成し、指定したポリシーをアタッチ
module "iam_user" {
  source = "./modules/iam"

  user_name               = var.iam_user_name           # 作成するIAMユーザーの名前
  create_access_key       = var.create_access_key       # アクセスキーを作成するかどうか
  create_login_profile    = var.create_login_profile    # コンソールログイン用のプロファイルを作成するかどうか
  password_reset_required = var.password_reset_required # 初回ログイン時にパスワード変更を要求するかどうか
  force_destroy           = var.force_destroy           # ユーザーを強制的に削除できるようにするかどうか
  policy_arns             = var.iam_policy_arns         # ユーザーにアタッチするIAMポリシーのARNのリスト
}

# S3バケットを作成するためのモジュール
# バケット名、アクセス制御、暗号化、ライフサイクルルールを設定
module "s3" {
  source = "./modules/s3"

  bucket_name        = var.s3_bucket_name                                                     # 作成するS3バケットの名前
  acl                = var.s3_acl                                                             # バケットのアクセスコントロールリスト（private, public-read等）
  force_destroy      = var.s3_force_destroy                                                   # バケットを強制的に削除できるようにするかどうか
  versioning_enabled = var.s3_versioning_enabled                                              # バージョニングを有効にするかどうか
  sse_enabled        = var.s3_sse_enabled                                                     # サーバーサイド暗号化を有効にするかどうか
  kms_key_id         = var.s3_kms_key_id != null ? var.s3_kms_key_id : module.kms.kms_key_arn # 暗号化に使用するKMSキーのID（指定がない場合は作成したKMSキーを使用）
  lifecycle_rules    = var.s3_lifecycle_rules                                                 # オブジェクトのライフサイクルルール設定
}
