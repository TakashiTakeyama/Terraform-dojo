locals {
  plan_buildspec = (
    length(trimspace(coalesce(var.plan_buildspec_inline, ""))) > 0
    ? { buildspec_inline = var.plan_buildspec_inline }
    : { buildspec_path = coalesce(var.plan_buildspec_path, "ci/terraform-plan.buildspec.yml") }
  )

  plan_namespace = (
    var.plan_namespace != null && trimspace(var.plan_namespace) != ""
    ? { namespace = var.plan_namespace }
    : {}
  )

  plan_stage = merge(
    {
      key                        = "plan"
      name                       = "Plan"
      image                      = var.plan_image
      compute_type               = var.plan_compute_type
      environment_type           = "LINUX_CONTAINER"
      privileged_mode            = var.plan_privileged_mode
      environment_variables      = var.plan_environment_variables
      additional_iam_policy_json = var.plan_stage_iam_policy_json
    },
    local.plan_buildspec,
    local.plan_namespace,
  )

  apply_buildspec = (
    length(trimspace(coalesce(var.apply_buildspec_inline, ""))) > 0
    ? { buildspec_inline = var.apply_buildspec_inline }
    : { buildspec_path = coalesce(var.apply_buildspec_path, "ci/terraform-apply.buildspec.yml") }
  )

  apply_stage = merge(
    {
      key                        = "apply"
      name                       = "Apply"
      image                      = var.apply_image
      compute_type               = var.apply_compute_type
      environment_type           = "LINUX_CONTAINER"
      privileged_mode            = var.apply_privileged_mode
      environment_variables      = var.apply_environment_variables
      additional_iam_policy_json = var.apply_stage_iam_policy_json
    },
    local.apply_buildspec,
  )
}

module "github_buildchain" {
  source = "../github-buildchain"

  name_prefix   = var.name_prefix
  pipeline_name = var.pipeline_name
  tags          = var.tags

  github_connection_arn = var.github_connection_arn
  full_repository_id    = var.full_repository_id
  branch_name           = var.branch_name

  source_detect_changes         = var.source_detect_changes
  trigger                       = var.trigger
  source_output_artifact_format = var.source_output_artifact_format

  create_artifact_bucket             = var.create_artifact_bucket
  artifact_s3_bucket_id              = var.artifact_s3_bucket_id
  artifact_s3_bucket_name            = var.artifact_s3_bucket_name
  artifact_store_kms_key_arn         = var.artifact_store_kms_key_arn
  artifact_bucket_force_destroy      = var.artifact_bucket_force_destroy
  artifact_lifecycle_expiration_days = var.artifact_lifecycle_expiration_days

  codebuild_stages = [local.plan_stage, local.apply_stage]

  codebuild_timeout_minutes           = var.codebuild_timeout_minutes
  codebuild_log_retention_days        = var.codebuild_log_retention_days
  codebuild_managed_policy_arns       = var.codebuild_managed_policy_arns
  pipeline_additional_iam_policy_json = var.pipeline_additional_iam_policy_json
  execution_mode                      = var.execution_mode
  enable_pipeline_cloudwatch_logs     = var.enable_pipeline_cloudwatch_logs
}
