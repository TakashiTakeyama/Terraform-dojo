data "aws_iam_policy_document" "lambda_deploy" {
  statement {
    sid    = "UpdateLambdaCode"
    effect = "Allow"
    actions = [
      "lambda:UpdateFunctionCode",
    ]
    resources = [
      "arn:aws:lambda:ap-northeast-1:000000000000:function:your-function-name",
    ]
  }
}
