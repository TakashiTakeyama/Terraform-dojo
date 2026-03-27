locals {
  build_buildspec = (
    length(trimspace(coalesce(var.build_buildspec_inline, ""))) > 0
    ? { buildspec_inline = var.build_buildspec_inline }
    : { buildspec_path = coalesce(var.build_buildspec_path, "buildspec.yml") }
  )

  build_namespace = (
    var.build_namespace != null && trimspace(var.build_namespace) != ""
    ? { namespace = var.build_namespace }
    : {}
  )

  build_stage = merge(
    {
      key                        = "build"
      name                       = "Build"
      image                      = var.build_image
      compute_type               = var.build_compute_type
      environment_type           = "LINUX_CONTAINER"
      privileged_mode            = var.build_privileged_mode
      environment_variables      = var.build_environment_variables
      additional_iam_policy_json = var.build_stage_iam_policy_json
    },
    local.build_buildspec,
    local.build_namespace,
  )

  deploy_buildspec = (
    length(trimspace(coalesce(var.deploy_buildspec_inline, ""))) > 0
    ? { buildspec_inline = var.deploy_buildspec_inline }
    : { buildspec_path = coalesce(var.deploy_buildspec_path, "deploy.buildspec.yml") }
  )

  deploy_stage = merge(
    {
      key                        = "deploy"
      name                       = "Deploy"
      image                      = var.deploy_image
      compute_type               = var.deploy_compute_type
      environment_type           = "LINUX_CONTAINER"
      privileged_mode            = var.deploy_privileged_mode
      environment_variables      = var.deploy_environment_variables
      additional_iam_policy_json = var.deploy_stage_iam_policy_json
    },
    local.deploy_buildspec,
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

  codebuild_stages = [local.build_stage, local.deploy_stage]

  codebuild_timeout_minutes           = var.codebuild_timeout_minutes
  codebuild_log_retention_days        = var.codebuild_log_retention_days
  codebuild_managed_policy_arns       = var.codebuild_managed_policy_arns
  pipeline_additional_iam_policy_json = var.pipeline_additional_iam_policy_json
  execution_mode                      = var.execution_mode
  enable_pipeline_cloudwatch_logs     = var.enable_pipeline_cloudwatch_logs
}
