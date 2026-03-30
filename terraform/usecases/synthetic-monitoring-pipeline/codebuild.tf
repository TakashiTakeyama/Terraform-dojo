resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/codebuild/${local.name_prefix}-synthetics-pipeline"
  retention_in_days = 30
}

# =============================================================================
# Build プロジェクト: canary-code を zip 化して S3 にアップロード
# =============================================================================

resource "aws_codebuild_project" "build" {
  name         = "${local.name_prefix}-synthetics-build"
  description  = "Zip canary code and upload to S3"
  service_role = aws_iam_role.build.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type = "CODEPIPELINE"
    buildspec = templatefile("${path.module}/spec/buildspec.yaml", {
      CANARY_CODE_BASE_PATH = var.canary_code_base_path
    })
  }

  # Graviton (ARM): x86 固有の依存がなく、同等性能で約20%のコスト削減が可能。
  # https://docs.aws.amazon.com/codebuild/latest/userguide/ec2-compute-images.html
  environment {
    type            = "ARM_CONTAINER"
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux-aarch64-standard:3.0"
    privileged_mode = false

    environment_variable {
      name  = "CANARY_S3_BUCKET"
      value = aws_s3_bucket.canary_deployments.bucket
    }
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE"]
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild.name
      status     = "ENABLED"
    }
  }

  build_timeout  = 15
  queued_timeout = 30
}

# --- Build IAM Role ---

data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "build" {
  name               = "${local.name_prefix}-synthetics-build-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}

data "aws_iam_policy_document" "build" {
  statement {
    sid    = "S3PipelineArtifactRead"
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${aws_s3_bucket.pipeline_artifacts.arn}/*",
    ]
  }

  statement {
    sid    = "S3CanaryDeploymentUpload"
    effect = "Allow"
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.canary_deployments.arn}/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "${aws_cloudwatch_log_group.codebuild.arn}:*",
    ]
  }
}

resource "aws_iam_role_policy" "build" {
  name   = "${local.name_prefix}-synthetics-build-policy"
  role   = aws_iam_role.build.id
  policy = data.aws_iam_policy_document.build.json
}

# =============================================================================
# Deploy プロジェクト: terraform apply で Canary リソースを更新
# =============================================================================

resource "aws_codebuild_project" "deploy" {
  name         = "${local.name_prefix}-synthetics-deploy"
  description  = "Run terraform apply to update canary resources"
  service_role = aws_iam_role.deploy.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type = "CODEPIPELINE"
    buildspec = templatefile("${path.module}/spec/deployspec.yaml", {
      ROOT_MODULE_PATH = var.monitoring_root_module_path
    })
  }

  # Graviton (ARM): x86 固有の依存がなく、同等性能で約20%のコスト削減が可能。
  environment {
    type            = "ARM_CONTAINER"
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux-aarch64-standard:3.0"
    privileged_mode = false
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE"]
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild.name
      status     = "ENABLED"
    }
  }

  build_timeout  = 15
  queued_timeout = 30
}

# --- Deploy IAM Role ---
# terraform plan/apply で多くのリソースを参照するため ReadOnlyAccess をアタッチし、
# 書き込み権限のみ個別に追加する。

data "aws_iam_policy" "read_only_access" {
  name = "ReadOnlyAccess"
}

resource "aws_iam_role" "deploy" {
  name               = "${local.name_prefix}-synthetics-deploy-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}

resource "aws_iam_role_policy_attachment" "deploy_read_only" {
  role       = aws_iam_role.deploy.name
  policy_arn = data.aws_iam_policy.read_only_access.arn
}

data "aws_iam_policy_document" "deploy" {
  # --- S3: Terraform state の読み書き ---
  statement {
    sid    = "S3TfstateAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${var.tfstate_bucket}",
      "arn:aws:s3:::${var.tfstate_bucket}/${var.tfstate_key}",
    ]
  }

  # --- Synthetics: Canary の作成・更新・削除 ---
  statement {
    sid    = "SyntheticsManageCanary"
    effect = "Allow"
    actions = [
      "synthetics:CreateCanary",
      "synthetics:UpdateCanary",
      "synthetics:DeleteCanary",
      "synthetics:TagResource",
    ]
    resources = [
      "arn:aws:synthetics:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:canary:${local.name_prefix}-web",
      "arn:aws:synthetics:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:canary:${local.name_prefix}-api",
    ]
  }

  # --- Lambda: Synthetics が内部で作成する Canary Lambda 関数の管理 ---
  # synthetics:CreateCanary / UpdateCanary / DeleteCanary は内部で Lambda 関数を
  # 作成・更新・削除するため、呼び出し元にも Lambda の書き込み権限が必要。
  # Canary Lambda の命名規則は cwsyn-<canary-name>-<id>。
  statement {
    sid    = "LambdaManageCanaryFunctions"
    effect = "Allow"
    actions = [
      "lambda:CreateFunction",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:PublishVersion",
      "lambda:DeleteFunction",
      "lambda:AddPermission",
      "lambda:TagResource",
      "lambda:UntagResource",
    ]
    resources = [
      "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:cwsyn-${local.name_prefix}-*",
    ]
  }

  # --- IAM: Canary 実行ロールの PassRole ---
  # synthetics:CreateCanary が Lambda 関数に execution_role_arn を設定する際に必要。
  # ロール名は synthetic-monitoring の aws_iam_role.canary_execution と一致させること。
  statement {
    sid    = "PassCanaryExecutionRole"
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.name_prefix}-synthetics-role",
    ]
  }

  # --- CloudWatch Logs: Canary ロググループとサブスクリプションフィルタの管理 ---
  statement {
    sid    = "CloudWatchLogsManageCanary"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:PutRetentionPolicy",
      "logs:TagResource",
      "logs:PutSubscriptionFilter",
      "logs:DeleteSubscriptionFilter",
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/cwsyn-*",
    ]
  }

  # --- CodeBuild ログ出力 ---
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "${aws_cloudwatch_log_group.codebuild.arn}:*",
    ]
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "${local.name_prefix}-synthetics-deploy-policy"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deploy.json
}
