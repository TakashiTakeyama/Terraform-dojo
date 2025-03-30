################################################################################
# GitHub OIDC Provider
# GitHub Actionsが発行するOIDCトークンを使用して、AWSリソースへのアクセスが可能になる
# このTerraformコード全体では、GitHub ActionsがAWSリソースにアクセスする際の認証とアクセス制御を、GitHub OIDCを利用してセキュアに実現しています。
# プロバイダー: GitHubのOIDCプロバイダーを設定し、GitHub Actionsの発行するトークンをAWSが信頼する仕組みを作ります。
# ロール: GitHub Actionsが引き受けるためのIAMロールを作成し、対象のアクションやユーザーを限定するための条件を追加しています。
# ポリシー: ロールに必要な権限（ここではEC2の読み取りとS3の読み取り専用）をアタッチし、必要なアクセスを実現しています。
# この設定により、GitHub Actionsから安全かつ柔軟にAWSリソースへアクセスするための仕組みが確立され、運用のセキュリティが大幅に向上します。
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

  # GitHubのOpenID Connectによるセキュリティ強化のドキュメントに従って
  # (https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
  # このドキュメントでは、クラウドプロバイダーの信頼関係を設定する際に利用可能なOIDCクレームを
  # 活用できることが多く言及されています。例えば、
  # https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect#customizing-the-token-claims
  # では、追加のOIDCトークンクレームを使用して詳細なOIDCポリシーを定義できると指定されています。
  # この例では、GitHubがAWS IAMロールを引き受けるために使用するOIDCトークンに正しい
  # 「actor」スコープがあることを確認します。
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
