data "aws_iam_policy_document" "pipeline_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "pipeline" {
  name               = "${var.name_prefix}-pipeline"
  assume_role_policy = data.aws_iam_policy_document.pipeline_assume.json

  tags = var.tags
}

data "aws_iam_policy_document" "pipeline_base" {
  statement {
    sid    = "ArtifactS3"
    effect = "Allow"
    actions = [
      "s3:GetBucketVersioning",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
    ]
    resources = [
      local.artifact_bucket_arn,
      "${local.artifact_bucket_arn}/*",
    ]
  }

  statement {
    sid    = "UseGitHubConnection"
    effect = "Allow"
    actions = [
      "codestar-connections:UseConnection",
      "codeconnections:UseConnection",
    ]
    resources = [var.github_connection_arn]
  }

  statement {
    sid    = "RunCodeBuild"
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "codebuild:BatchGetProjects",
    ]
    resources = [for p in aws_codebuild_project.stage : p.arn]
  }

  dynamic "statement" {
    for_each = var.enable_pipeline_cloudwatch_logs ? [1] : []
    content {
      sid    = "PipelineLogs"
      effect = "Allow"
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
      resources = [
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codepipeline/${local.pipeline_name}",
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codepipeline/${local.pipeline_name}:log-stream:*",
      ]
    }
  }
}

data "aws_iam_policy_document" "pipeline_effective" {
  source_policy_documents = (
    trimspace(coalesce(var.pipeline_additional_iam_policy_json, "")) != ""
    ? [data.aws_iam_policy_document.pipeline_base.json, var.pipeline_additional_iam_policy_json]
    : [data.aws_iam_policy_document.pipeline_base.json]
  )
}

resource "aws_iam_role_policy" "pipeline" {
  name   = "${var.name_prefix}-pipeline-inline"
  role   = aws_iam_role.pipeline.id
  policy = data.aws_iam_policy_document.pipeline_effective.json
}
