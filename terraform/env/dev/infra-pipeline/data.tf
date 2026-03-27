data "aws_iam_policy_document" "tf_plan" {
  statement {
    sid    = "ReadState"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::your-tf-state-bucket",
      "arn:aws:s3:::your-tf-state-bucket/env/dev/*",
    ]
  }

  statement {
    sid    = "StateLock"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]
    resources = [
      "arn:aws:dynamodb:ap-northeast-1:000000000000:table/your-tf-lock-table",
    ]
  }
}

data "aws_iam_policy_document" "tf_apply" {
  statement {
    sid    = "StateAndLock"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::your-tf-state-bucket",
      "arn:aws:s3:::your-tf-state-bucket/env/dev/*",
    ]
  }

  statement {
    sid    = "StateLockApply"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]
    resources = [
      "arn:aws:dynamodb:ap-northeast-1:000000000000:table/your-tf-lock-table",
    ]
  }

  statement {
    sid    = "AssumeApplyRole"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    # 本番では Terraform apply が必要とするロール ARN に絞ること
    resources = [
      "arn:aws:iam::000000000000:role/terraform-apply-role",
    ]
  }
}
