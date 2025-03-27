data "aws_region" "current" {}

data "template_file" "swagger" {
  for_each = var.apis

  template = file("${path.module}/swagger.yaml")
  vars = {
    description         = "REST API Gateway for ${var.company_name}-${var.product_name}-${var.project_name}"
    title               = "${var.company_name}-${var.product_name}-${var.project_name}-${var.env}-${each.value.api_name}"
    stage_name          = "${each.value.api_stage_name}"
    resource_path       = "${each.value.api_resource_path}"
    http_method         = "${each.value.api_method}"
    aws_region          = "${data.aws_region.current.name}"
    lambda_function_arn = var.lambda_function_arns[each.value.lambda_name]
  }
}