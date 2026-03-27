# アプリ用パイプラインとは別 root・別 state で置く。
module "infra_cd" {
  source = "../../../../modules/codepipeline/pipeline-infra-tf"

  name_prefix = local.name_prefix

  github_connection_arn = local.github_connection_arn
  full_repository_id    = local.full_repository_id
  branch_name           = local.branch_name

  trigger = local.trigger

  plan_buildspec_path  = local.plan_buildspec_path
  apply_buildspec_path = local.apply_buildspec_path

  plan_stage_iam_policy_json  = data.aws_iam_policy_document.tf_plan.json
  apply_stage_iam_policy_json = data.aws_iam_policy_document.tf_apply.json
}

output "pipeline_name" {
  value = module.infra_cd.pipeline_name
}

output "codebuild_project_names" {
  value = module.infra_cd.codebuild_project_names
}
