# コンテナイメージを使用したLambda関数の作成
module "lambda_function_container_image" {
  # AWS Lambda用のTerraformモジュールを使用
  source = "terraform-aws-modules/lambda/aws"

  # Lambda関数の基本設定
  function_name = var.function_name # 関数名
  description   = var.description   # 関数の説明

  # パッケージ作成の無効化（コンテナイメージを使用するため）
  create_package = false

  # コンテナイメージの設定
  image_uri    = var.image_uri # コンテナイメージのURI
  package_type = "Image"       # パッケージタイプをImageに指定
}