# 呼び出し元 root で値をまとめて定義する（tfvars は使わない）。
locals {
  aws_region = "ap-northeast-1"

  name_prefix           = "example-build-only"
  github_connection_arn = "arn:aws:codeconnections:ap-northeast-1:000000000000:connection/REPLACE_ME"
  full_repository_id    = "your-org/your-repo"
  branch_name           = "main"

  build_trigger = {
    branches   = ["main"]
    file_paths = ["src/**", "buildspec.yml"]
  }
}
