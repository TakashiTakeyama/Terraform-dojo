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

# ECRリポジトリを作成・管理するためのモジュール
# 開発環境用のリポジトリとアクセス権限を設定
module "ecr" {
  source = "./modules/ecr"

  dev_repos                = var.dev_repos                # ECRリポジトリの設定
  ga_role_names            = var.ga_role_names            # GitHub Actions用ロール名
  github_oidc_provider_arn = var.github_oidc_provider_arn # GitHub OIDC プロバイダーのARN
}

# VPCを作成するためのモジュール
# VPCの作成、サブネットの設定、Flow Logsの設定を行う
# - パブリック/プライベートサブネットを各AZに作成
# - NATゲートウェイを有効化(シングル構成)
# - VPC Flow LogsをS3またはCloudWatch Logsに出力
module "vpc" {
  source = "./modules/vpc"

  vpc_name           = var.vpc_name           # VPCの名前
  destination_s3_arn = var.destination_s3_arn # Flow Logs出力先のS3バケットARN(nullの場合はCloudWatch Logs)
}

# コンテナイメージを使用してLambda関数をデプロイするためのモジュール
# - function_name: Lambda関数の名前を指定
# - description: Lambda関数の説明文を設定 
# - image_uri: デプロイするコンテナイメージのURIを指定
module "lambda_function_container_image" {
  source = "./modules/lambda/container-iamge"

  function_name = var.function_name
  description   = var.description
  image_uri     = var.image_uri
}
