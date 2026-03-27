# 型 A: Source → Build（1 段）
module "pipeline_build_only" {
  source = "../../../../modules/codepipeline/github-buildchain"

  name_prefix = local.name_prefix

  github_connection_arn = local.github_connection_arn
  full_repository_id    = local.full_repository_id
  branch_name           = local.branch_name

  trigger = local.build_trigger

  artifact_lifecycle_expiration_days = 30

  codebuild_stages = [
    {
      key              = "build"
      name             = "Build"
      buildspec_inline = <<-EOT
        version: 0.2
        phases:
          build:
            commands:
              - echo "Replace with your build commands"
      EOT
    }
  ]
}
output "pipeline_name" {
  value = module.pipeline_build_only.pipeline_name
}

output "codebuild_project_names" {
  value = module.pipeline_build_only.codebuild_project_names
}

