output "pipeline_name" {
  description = "CodePipeline 名。"
  value       = module.github_buildchain.pipeline_name
}

output "pipeline_arn" {
  description = "CodePipeline ARN。"
  value       = module.github_buildchain.pipeline_arn
}

output "artifact_s3_bucket_id" {
  description = "成果物バケット名。"
  value       = module.github_buildchain.artifact_s3_bucket_id
}

output "artifact_s3_bucket_arn" {
  description = "成果物バケット ARN。"
  value       = module.github_buildchain.artifact_s3_bucket_arn
}

output "codebuild_project_names" {
  description = "ステージ key（build / deploy）→ CodeBuild プロジェクト名。"
  value       = module.github_buildchain.codebuild_project_names
}

output "codebuild_role_arns" {
  description = "ステージ key → CodeBuild ロール ARN。"
  value       = module.github_buildchain.codebuild_role_arns
}

output "pipeline_role_arn" {
  description = "CodePipeline ロール ARN。"
  value       = module.github_buildchain.pipeline_role_arn
}
