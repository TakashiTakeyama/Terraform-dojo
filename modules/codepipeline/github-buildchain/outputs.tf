output "pipeline_name" {
  description = "CodePipeline 名。"
  value       = aws_codepipeline.this.name
}

output "pipeline_arn" {
  description = "CodePipeline ARN。"
  value       = aws_codepipeline.this.arn
}

output "artifact_s3_bucket_id" {
  description = "パイプライン成果物バケット名。"
  value       = local.artifact_bucket_id
}

output "artifact_s3_bucket_arn" {
  description = "パイプライン成果物バケット ARN。後続リソースの IAM ポリシーで参照する場合に利用。"
  value       = local.artifact_bucket_arn
}

output "codebuild_project_names" {
  description = "ステージ key → CodeBuild プロジェクト名。"
  value       = { for k, p in aws_codebuild_project.stage : k => p.name }
}

output "codebuild_role_arns" {
  description = "ステージ key → CodeBuild 用 IAM ロール ARN（ステージごとにデプロイ権限を分けられる）。"
  value       = { for k, r in aws_iam_role.codebuild : k => r.arn }
}

output "pipeline_role_arn" {
  description = "CodePipeline 用 IAM ロール ARN。"
  value       = aws_iam_role.pipeline.arn
}
