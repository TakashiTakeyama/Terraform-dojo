resource "aws_codepipeline" "this" {
  lifecycle {
    precondition {
      condition     = var.create_artifact_bucket || length(trimspace(coalesce(var.artifact_s3_bucket_id, ""))) > 0
      error_message = "create_artifact_bucket が false のときは artifact_s3_bucket_id に既存バケット名を指定してください。"
    }
  }

  name     = local.pipeline_name
  role_arn = aws_iam_role.pipeline.arn

  pipeline_type  = "V2"
  execution_mode = var.execution_mode

  tags = var.tags

  artifact_store {
    location = local.artifact_bucket_id
    type     = "S3"

    dynamic "encryption_key" {
      for_each = var.artifact_store_kms_key_arn != null ? [1] : []
      content {
        id   = var.artifact_store_kms_key_arn
        type = "KMS"
      }
    }
  }

  # V2 トリガー：ブランチ＋パスフィルタ（プッシュ）
  dynamic "trigger" {
    for_each = local.trigger_has_push_filter ? [1] : []
    content {
      provider_type = "CodeStarSourceConnection"
      git_configuration {
        source_action_name = "FetchSource"
        dynamic "push" {
          for_each = [1]
          content {
            dynamic "branches" {
              for_each = length(coalesce(var.trigger.branches, [])) > 0 ? [1] : []
              content {
                includes = var.trigger.branches
              }
            }
            dynamic "file_paths" {
              for_each = length(coalesce(var.trigger.file_paths, [])) > 0 ? [1] : []
              content {
                includes = var.trigger.file_paths
              }
            }
          }
        }
      }
    }
  }

  # V2 トリガー：タグ
  dynamic "trigger" {
    for_each = local.trigger_has_tag_filter ? [1] : []
    content {
      provider_type = "CodeStarSourceConnection"
      git_configuration {
        source_action_name = "FetchSource"
        push {
          tags {
            includes = var.trigger.tags
          }
        }
      }
    }
  }

  stage {
    name = "Source"
    action {
      name             = "FetchSource"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = [local.source_output_name]
      configuration = {
        ConnectionArn        = var.github_connection_arn
        FullRepositoryId     = var.full_repository_id
        BranchName           = var.branch_name
        DetectChanges        = local.source_detect_changes_effective ? "true" : "false"
        OutputArtifactFormat = var.source_output_artifact_format
      }
    }
  }

  dynamic "stage" {
    for_each = local.stages_ordered
    content {
      name = stage.value.name
      action {
        name             = "Run_${replace(stage.value.key, "/[^A-Za-z0-9_]/", "_")}"
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        version          = "1"
        namespace        = stage.value.namespace
        input_artifacts  = [local.stage_input_artifact[stage.value.key]]
        output_artifacts = [local.stage_output_artifact[stage.value.key]]
        configuration = {
          ProjectName = aws_codebuild_project.stage[stage.value.key].name
        }
      }
    }
  }
}
