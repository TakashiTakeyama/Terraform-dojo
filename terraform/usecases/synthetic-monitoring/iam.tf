data "aws_iam_policy_document" "canary_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# 名前を変更する場合は synthetic-monitoring-pipeline の codebuild.tf にある
# iam:PassRole（PassCanaryExecutionRole）の resources も同じ名前に合わせること。
resource "aws_iam_role" "canary_execution" {
  name               = "${local.name_prefix}-synthetics-role"
  assume_role_policy = data.aws_iam_policy_document.canary_assume_role.json
}

data "aws_iam_policy_document" "canary_execution" {
  # アーティファクトバケットへの読み書き
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
    ]
    resources = ["${aws_s3_bucket.canary_artifacts.arn}/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]
    resources = [aws_s3_bucket.canary_artifacts.arn]
  }

  # デプロイメントバケットからの canary zip 読み取り
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
    resources = ["${data.aws_s3_bucket.canary_deployments.arn}/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]
    resources = [data.aws_s3_bucket.canary_deployments.arn]
  }

  # Canary Lambda のログ出力
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/cwsyn-*",
    ]
  }

  # CloudWatch Synthetics メトリクス送信
  statement {
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["CloudWatchSynthetics"]
    }
  }

  # Web canary 用のシークレット読み取り
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [aws_secretsmanager_secret.web_signin.arn]
  }
}

resource "aws_iam_role_policy" "canary_execution" {
  name   = "${local.name_prefix}-synthetics-policy"
  role   = aws_iam_role.canary_execution.id
  policy = data.aws_iam_policy_document.canary_execution.json
}
