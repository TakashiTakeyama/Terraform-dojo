output "ecr" {
  description = "作成されたECRリポジトリの情報"
  value       = module.repos
}

output "name" {
  description = "作成されたECRリポジトリ名のリスト"
  value       = local.dev_repos_flat
}

output "github_actions_role_arn" {
  description = "GitHub Actions用のIAMロールのARN"
  value       = { for role_name, role in aws_iam_role.github_actions_role : role_name => role.arn }
}
