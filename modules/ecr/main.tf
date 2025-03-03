# ECRリポジトリの作成
# dev_repos_flatの各要素に対してECRリポジトリを作成する
module "repos" {
  source          = "terraform-aws-modules/ecr/aws"
  for_each        = { for item in local.dev_repos_flat : item.repository_name => item }
  repository_name = each.value.repository_name
  # イメージスキャンの設定
  manage_registry_scanning_configuration = true
  registry_scan_type                     = "BASIC"
  registry_scan_rules = [
    {
      scan_frequency = "SCAN_ON_PUSH" # イメージプッシュ時にスキャンを実行
      filter = [
        {
          filter      = "*" # すべてのイメージに適用
          filter_type = "WILDCARD"
        },
      ]
    }
  ]
  # リポジトリへのアクセス権限設定
  repository_read_write_access_arns  = each.value.repo_access_arns
  repository_lambda_read_access_arns = each.value.lambda_access_arns
  # ライフサイクルポリシーの設定
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"], # vタグが付いているイメージが対象
          countType     = "imageCountMoreThan",
          countNumber   = 30 # 30個以上のイメージがある場合
        },
        action = {
          type = "expire" # 古いイメージを削除
        }
      }
    ]
  })
}

################################################################################
# GitHub OIDC Role
################################################################################

# GitHub Actions用のIAMロールを作成
resource "aws_iam_role" "github_actions_role" {
  for_each = toset(var.ga_role_names)
  name     = each.value
  # OIDCプロバイダーを使用したロールの信頼ポリシー
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = var.github_oidc_provider_arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub" : ["repo:mobilus-co-jp/*"] # Mobilusの組織配下のリポジトリのみ許可
          }
        }
      }
    ]
  })
}

# GitHub Actions用のロールにECRへのアクセス権限を付与
resource "aws_iam_role_policy_attachment" "ecr_access" {
  for_each   = toset(var.ga_role_names)
  role       = aws_iam_role.github_actions_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}
