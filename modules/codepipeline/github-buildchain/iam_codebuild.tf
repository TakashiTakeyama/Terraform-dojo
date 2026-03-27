data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild" {
  for_each = { for s in var.codebuild_stages : s.key => s }

  name               = "${var.name_prefix}-cb-${each.key}"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json

  tags = var.tags
}

data "aws_iam_policy_document" "codebuild_base" {
  for_each = { for s in var.codebuild_stages : s.key => s }

  statement {
    sid    = "ArtifactS3"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:GetBucketVersioning",
      "s3:GetBucketLocation",
    ]
    resources = [
      local.artifact_bucket_arn,
      "${local.artifact_bucket_arn}/*",
    ]
  }

  statement {
    sid    = "Logs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.codebuild[each.key].arn}:*"]
  }
}

data "aws_iam_policy_document" "codebuild_effective" {
  for_each = { for s in var.codebuild_stages : s.key => s }

  source_policy_documents = (
    trimspace(coalesce(each.value.additional_iam_policy_json, "")) != ""
    ? [data.aws_iam_policy_document.codebuild_base[each.key].json, each.value.additional_iam_policy_json]
    : [data.aws_iam_policy_document.codebuild_base[each.key].json]
  )
}

resource "aws_iam_role_policy" "codebuild" {
  for_each = { for s in var.codebuild_stages : s.key => s }

  name   = "${var.name_prefix}-cb-${each.key}-inline"
  role   = aws_iam_role.codebuild[each.key].id
  policy = data.aws_iam_policy_document.codebuild_effective[each.key].json
}

resource "aws_iam_role_policy_attachment" "codebuild_managed" {
  for_each = local.codebuild_managed_policy_attachments

  role       = aws_iam_role.codebuild[each.value.stage_key].name
  policy_arn = each.value.policy_arn
}
