# 現在のAWSリージョンを取得
data "aws_region" "current" {}

# Swaggerテンプレートファイルを読み込み、変数を置換
data "template_file" "swagger" {
  for_each = var.apis                            # 定義されたAPI設定ごとにテンプレートを生成
  template = file("${path.module}/swagger.yaml") # Terraform-dojo/modules/apigateway/HTTP/swagger/swagger.yaml
  vars = {
    description = "REST API Gateway for ${var.company_name}-${var.product_name}-${var.project_name}"
    # APIのタイトル（命名規則に従って構成）
    title = "${var.company_name}-${var.product_name}-${var.project_name}-${var.env}-${each.value.api_name}"
    # APIのステージ名
    stage_name = "${each.value.api_stage_name}"
    # APIのリソースパス
    resource_path = "${each.value.api_resource_path}"
    # APIで使用するHTTPメソッド
    http_method = "${each.value.api_method}"
    aws_region  = "${data.aws_region.current.name}"
    # 統合するLambda関数のARN
    lambda_function_arn = var.lambda_function_arns[each.value.lambda_name]
  }
}