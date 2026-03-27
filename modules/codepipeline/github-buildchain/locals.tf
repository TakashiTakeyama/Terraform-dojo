locals {
  pipeline_name      = coalesce(var.pipeline_name, "${var.name_prefix}-pipeline")
  source_output_name = "SourceArtifact"

  # trigger を指定した場合は DetectChanges を強制 false にする
  source_detect_changes_effective = var.trigger != null ? false : var.source_detect_changes

  # trigger の種別ごとに dynamic で出し分ける際のフラグ
  trigger_has_push_filter = (
    var.trigger != null &&
    (length(coalesce(var.trigger.branches, [])) > 0 || length(coalesce(var.trigger.file_paths, [])) > 0)
  )
  trigger_has_tag_filter = (
    var.trigger != null && length(coalesce(var.trigger.tags, [])) > 0
  )

  # パイプライン stage の順序をリスト順に保つ（キーは 000,001,...）
  stages_ordered = {
    for i, s in var.codebuild_stages :
    format("%03d", i) => merge(s, { index = i })
  }

  stage_output_artifact = {
    for s in var.codebuild_stages :
    s.key => "${replace(s.key, "/[^A-Za-z0-9@_-]/", "_")}_out"
  }

  stage_input_artifact = {
    for i, s in var.codebuild_stages :
    s.key => (
      i == 0 ? local.source_output_name : local.stage_output_artifact[var.codebuild_stages[i - 1].key]
    )
  }

  artifact_bucket_id  = var.create_artifact_bucket ? aws_s3_bucket.pipeline_artifacts[0].id : var.artifact_s3_bucket_id
  artifact_bucket_arn = var.create_artifact_bucket ? aws_s3_bucket.pipeline_artifacts[0].arn : data.aws_s3_bucket.existing_artifacts[0].arn

  # 各 CodeBuild ロールへ共通の管理ポリシーを (stage_key, index) 単位でアタッチ
  codebuild_managed_policy_attachments = length(var.codebuild_managed_policy_arns) == 0 ? {} : {
    for pair in flatten([
      for stage in var.codebuild_stages : [
        for idx, pol in var.codebuild_managed_policy_arns : {
          attach_key = "${stage.key}-${idx}"
          stage_key  = stage.key
          policy_arn = pol
        }
      ]
    ]) : pair.attach_key => pair
  }

  codebuild_buildspec = {
    for s in var.codebuild_stages : s.key => (
      trimspace(coalesce(s.buildspec_inline, "")) != ""
      ? s.buildspec_inline
      : coalesce(s.buildspec_path, "buildspec.yml")
    )
  }
}
