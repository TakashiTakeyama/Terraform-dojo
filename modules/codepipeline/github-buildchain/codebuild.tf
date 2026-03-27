resource "aws_cloudwatch_log_group" "codebuild" {
  for_each = { for s in var.codebuild_stages : s.key => s }

  name              = "/aws/codebuild/${var.name_prefix}-${each.key}"
  retention_in_days = var.codebuild_log_retention_days

  tags = var.tags
}

resource "aws_codebuild_project" "stage" {
  for_each = { for s in var.codebuild_stages : s.key => s }

  name          = "${var.name_prefix}-${each.key}"
  service_role  = aws_iam_role.codebuild[each.key].arn
  build_timeout = var.codebuild_timeout_minutes

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = each.value.compute_type
    image                       = each.value.image
    type                        = each.value.environment_type
    privileged_mode             = each.value.privileged_mode
    image_pull_credentials_type = "CODEBUILD"

    dynamic "environment_variable" {
      for_each = coalesce(each.value.environment_variables, {})
      content {
        name  = environment_variable.key
        value = environment_variable.value
        type  = "PLAINTEXT"
      }
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild[each.key].name
      stream_name = "build"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = local.codebuild_buildspec[each.key]
  }

  tags = var.tags
}
