locals {
  # ECRリポジトリの設定をフラット化
  # var.dev_reposの各要素に対して、repo_namesの各要素をマップ形式に変換
  # repository_name: リポジトリ名
  # repo_access_arns: リポジトリへのアクセス権限を持つIAMロールのARN
  # lambda_access_arns: Lambda関数からのアクセス権限を持つIAMロールのARN
  dev_repos_flat = flatten([
    for k, v in var.dev_repos : [
      for r in v.repo_names : {
        repository_name    = r
        repo_access_arns   = repo_val.repo_access_arns
        lambda_access_arns = repo_val.lambda_access_arns
      }
    ]
  ])
  # サンプルtfvars
  # dev_repos = {
  #   "api" = {
  #     repo_names = [
  #       "backend-api",
  #       "frontend-app"
  #     ]
  #     repo_access_arns = [
  #       "arn:aws:iam::123456789012:role/developer-role",
  #       "arn:aws:iam::123456789012:user/ci-user"
  #     ]
  #     lambda_access_arns = [
  #       "arn:aws:iam::123456789012:role/lambda-execution-role"
  #     ]
  #   },
  #   "batch" = {
  #     repo_names = [
  #       "daily-batch",
  #       "weekly-batch"
  #     ]
  #     repo_access_arns = [
  #       "arn:aws:iam::123456789012:role/batch-role"
  #     ]
  #     lambda_access_arns = []
  #   }
  # }
}
