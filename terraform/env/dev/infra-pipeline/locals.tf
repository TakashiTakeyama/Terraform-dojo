# アプリ用パイプラインとは別 root・別 state で置く。
locals {
  aws_region  = "ap-northeast-1"
  name_prefix = "example-infra-tf-dev"

  github_connection_arn = "arn:aws:codeconnections:ap-northeast-1:000000000000:connection/REPLACE_ME"
  full_repository_id    = "your-org/your-infra-repo"
  branch_name           = "main"

  trigger = {
    branches   = ["main"]
    file_paths = ["terraform/**", "ci/terraform-*.buildspec.yml"]
  }

  plan_buildspec_path  = "ci/terraform-plan.buildspec.yml"
  apply_buildspec_path = "ci/terraform-apply.buildspec.yml"
}
