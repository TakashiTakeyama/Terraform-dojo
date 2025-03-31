################################################################################
# GitHub OIDC Provider
# GitHub Actionsが発行するOIDCトークンを使用して、AWSリソースへのアクセスが可能になる
################################################################################

module "iam_github_oidc_provider" {
  source = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"
}

module "iam_github_oidc_provider_disabled" {
  source = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"

  create = false # プロバイダーを作成しない設定
}

################################################################################
# GitHub OIDC Role
################################################################################

module "iam_github_oidc_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"

  name = var.name # ロール名

  # これは組織、リポジトリ、参照/ブランチなどに合わせて更新する必要があります
  subjects = [
    # 「repo:」を先頭に付けることもできますが、必須ではありません
    "repo:terraform-aws-modules/terraform-aws-iam:pull_request",
    "terraform-aws-modules/terraform-aws-iam:ref:refs/heads/master",
  ]

  # 「actor」スコープがあることを確認します 信頼ポリシー
  additional_trust_policy_conditions = [
    {
      test     = "StringEquals"
      variable = "${module.iam_github_oidc_provider.url}:actor"
      # これは、ロールへのアクセスを制限したいGitHubユーザー名のリストである必要があります
      values = ["username"]
    }
  ]

  policies = {
    additional = aws_iam_policy.additional.arn                    # 追加ポリシーのARN
    S3ReadOnly = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess" # S3読み取り専用ポリシー
  }
}

module "iam_github_oidc_role_disabled" {
  source = "../../modules/iam-github-oidc-role"

  create = false # ロールを作成しない設定
}

################################################################################
# Supporting Resources
################################################################################

resource "aws_iam_policy" "additional" {
  name        = "${var.name}-additional" # ポリシー名
  description = "Additional test policy" # ポリシーの説明

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*", # EC2リソースの情報取得権限
        ]
        Effect   = "Allow"
        Resource = "*" # すべてのリソースに適用
      },
    ]
  })
}
