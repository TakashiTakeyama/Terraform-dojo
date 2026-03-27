module "lambda_cd" {
  source = "../../../../modules/codepipeline/pipeline-app-lambda"

  name_prefix = local.name_prefix

  github_connection_arn = local.github_connection_arn
  full_repository_id    = local.full_repository_id
  branch_name           = local.branch_name

  trigger = local.trigger

  build_buildspec_path  = local.build_buildspec_path
  deploy_buildspec_path = local.deploy_buildspec_path

  deploy_stage_iam_policy_json = data.aws_iam_policy_document.lambda_deploy.json
}

output "pipeline_name" {
  value = module.lambda_cd.pipeline_name
}

output "codebuild_project_names" {
  value = module.lambda_cd.codebuild_project_names
}
