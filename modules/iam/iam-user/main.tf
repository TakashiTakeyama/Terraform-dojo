# IAMユーザーを作成するモジュール
# terraform-aws-modules/iam/aws//modules/iam-user モジュールを使用
module "iam_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user" # IAMユーザーモジュールのソース
  version = "~> 5.0"                                          # モジュールのバージョン

  name                          = var.user_name               # IAMユーザー名
  create_iam_access_key         = var.create_access_key       # アクセスキーを作成するかどうか
  create_iam_user_login_profile = var.create_login_profile    # ログインプロファイルを作成するかどうか
  password_reset_required       = var.password_reset_required # パスワードリセットを要求するかどうか
  force_destroy                 = var.force_destroy           # ユーザーを強制的に削除するかどうか

  # ポリシーのアタッチ
  # 指定したポリシーARNのリストをユーザーにアタッチする
  policy_arns = var.policy_arns
}
