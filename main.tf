#####################################################################################
# SSM EC2
#####################################################################################

# SSM経由でEC2インスタンスを管理するためのモジュール
module "ssm_ec2" {
  source = "./modules/ssm-ec2"

  vpc_name        = var.vpc_name        # VPCの名前
  workspaces_name = var.workspaces_name # WorkSpacesの名前
  ssm_ec2         = var.ssm_ec2         # SSMの設定
  user_data       = var.user_data       # EC2起動時に実行するユーザーデータスクリプト
  ami_name        = var.ami_name        # 使用するAMIの名前
}

#####################################################################################
# KMS
#####################################################################################

# KMSキーを作成・管理するためのモジュール
module "kms" {
  source = "./modules/kms"

  key_administrators = var.key_administrators # KMSキーの管理者権限を付与するIAMユーザーのリスト
  aliases            = var.aliases            # KMSキーに設定するエイリアスのリスト
}

#####################################################################################
# IAM
#####################################################################################

# IAMユーザーを作成するためのモジュール
module "iam_user" {
  source = "./modules/iam"

  user_name               = var.iam_user_name           # 作成するIAMユーザーの名前
  create_access_key       = var.create_access_key       # アクセスキーを作成するかどうか
  create_login_profile    = var.create_login_profile    # コンソールログイン用のプロファイルを作成するかどうか
  password_reset_required = var.password_reset_required # 初回ログイン時にパスワード変更を要求するかどうか
  force_destroy           = var.force_destroy           # ユーザーを強制的に削除できるようにするかどうか
  policy_arns             = var.iam_policy_arns         # ユーザーにアタッチするIAMポリシーのARNのリスト
}

#####################################################################################
# S3
#####################################################################################

# S3バケットを作成するためのモジュール
module "s3" {
  source = "./modules/s3"

  bucket_name        = var.s3_bucket_name                                                     # 作成するS3バケットの名前
  acl                = var.s3_acl                                                             # バケットのアクセスコントロールリスト
  force_destroy      = var.s3_force_destroy                                                   # バケットを強制的に削除できるようにするかどうか
  versioning_enabled = var.s3_versioning_enabled                                              # バージョニングを有効にするかどうか
  sse_enabled        = var.s3_sse_enabled                                                     # サーバーサイド暗号化を有効にするかどうか
  kms_key_id         = var.s3_kms_key_id != null ? var.s3_kms_key_id : module.kms.kms_key_arn # 暗号化に使用するKMSキーのID
  lifecycle_rules    = var.s3_lifecycle_rules                                                 # オブジェクトのライフサイクルルール設定
}

#####################################################################################
# ECR
#####################################################################################

# ECRリポジトリを作成・管理するためのモジュール
module "ecr" {
  source = "./modules/ecr"

  dev_repos                = var.dev_repos                # ECRリポジトリの設定
  ga_role_names            = var.ga_role_names            # GitHub Actions用ロール名
  github_oidc_provider_arn = var.github_oidc_provider_arn # GitHub OIDC プロバイダーのARN
}

#####################################################################################
# VPC
#####################################################################################

# VPCを作成するためのモジュール
module "vpc" {
  source = "./modules/vpc"

  vpc_name           = var.vpc_name           # VPCの名前
  destination_s3_arn = var.destination_s3_arn # Flow Logs出力先のS3バケットARN
}

#####################################################################################
# Lambda
#####################################################################################

# コンテナイメージを使用してLambda関数をデプロイするためのモジュール
module "lambda_function_container_image" {
  source = "./modules/lambda/container-iamge"

  function_name = var.function_name # Lambda関数の名前
  description   = var.description   # Lambda関数の説明文
  image_uri     = var.image_uri     # デプロイするコンテナイメージのURI
}

#####################################################################################
# CloudFront
#####################################################################################

# CloudFrontディストリビューションを作成するためのモジュール
module "cloudfront" {
  source = "./modules/cloudfront"

  aliases                                = var.cloudfront.aliases                                # カスタムドメイン
  comment                                = var.cloudfront.comment                                # ディストリビューションの説明文
  enabled                                = var.cloudfront.enabled                                # ディストリビューションの有効/無効
  is_ipv6_enabled                        = var.cloudfront.is_ipv6_enabled                        # IPv6サポートの有効/無効
  price_class                            = var.cloudfront.price_class                            # エッジロケーションの範囲
  origin_access_identities               = var.cloudfront.origin_access_identities               # S3バケットアクセス用のOAI
  logging_config_bucket                  = var.cloudfront.logging_config_bucket                  # アクセスログ保存用S3バケット
  s3_origin_config_domain_name           = var.cloudfront.s3_origin_config_domain_name           # オリジンS3バケットのドメイン名
  viewer_certificate_acm_certificate_arn = var.cloudfront.viewer_certificate_acm_certificate_arn # HTTPS通信用ACM証明書ARN
}
