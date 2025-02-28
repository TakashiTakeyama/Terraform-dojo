################################################################################
# EC2
################################################################################

# EC2インスタンスを作成
# terraform-aws-modules/ec2-instance/aws モジュールを使用
module "ssm_ec2" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  ami                    = data.aws_ami.amazon_linux_23.id               # Amazon Linux 2023 AMIを使用
  name                   = "${var.workspaces_name}-ssm-ec2"              # インスタンス名
  instance_type          = var.ssm_ec2.instance_type                     # インスタンスタイプ
  iam_instance_profile   = aws_iam_instance_profile.profile_ssm_ec2.name # IAMインスタンスプロファイル
  vpc_security_group_ids = [module.ssm_ec2_sg.security_group_id]         # セキュリティグループ
  subnet_id              = var.ssm_ec2.subnet_id                         # サブネットID
  user_data              = var.user_data                                 # ユーザーデータ
}

################################################################################
# SG
################################################################################

# セキュリティグループを作成
# terraform-aws-modules/security-group/aws モジュールを使用
module "ssm_ec2_sg" {
  source             = "terraform-aws-modules/security-group/aws"
  name               = "${var.workspaces_name}-ssm-ec2-sg" # セキュリティグループ名
  description        = "SSM EC2 for Security Group"        # 説明
  vpc_id             = data.aws_vpc.main_vpc.id            # VPC ID
  egress_cidr_blocks = ["0.0.0.0/0"]                       # 送信先CIDRブロック
  egress_rules       = ["all-all"]                         # 送信ルール（全て許可）
}

################################################################################
# IAM
################################################################################

# IAMインスタンスプロファイルを作成
resource "aws_iam_instance_profile" "profile_ssm_ec2" {
  name = module.iam_assumable_role_for_ssm_ec2.iam_role_name # プロファイル名
  role = module.iam_assumable_role_for_ssm_ec2.iam_role_name # ロール名
}

# IAMロールを作成
# terraform-aws-modules/iam/aws//modules/iam-assumable-role モジュールを使用
module "iam_assumable_role_for_ssm_ec2" {
  source      = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  create_role = true
  role_name   = "${var.workspaces_name}-role-for-ssm-ec2" # ロール名

  # 信頼ポリシーの設定
  trusted_role_services = [
    "ec2.amazonaws.com" # EC2サービスからの引き受けを許可
  ]
  trusted_role_actions = [
    "sts:AssumeRole" # AssumeRole権限を付与
  ]

  # アタッチするポリシー
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", # Systems Manager用のポリシー
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",           # S3へのフルアクセス権限
    "arn:aws:iam::aws:policy/CloudWatchAgentAdminPolicy"    # CloudWatchエージェント用のポリシー
  ]
  role_requires_mfa                 = false # MFA認証不要
  number_of_custom_role_policy_arns = 3     # アタッチするポリシーの数
}