locals {
  aws_region  = "ap-northeast-1"
  name_prefix = "example-lambda-dev"

  github_connection_arn = "arn:aws:codeconnections:ap-northeast-1:000000000000:connection/REPLACE_ME"
  full_repository_id    = "your-org/your-lambda-app"
  branch_name           = "main"

  trigger = {
    branches   = ["main"]
    file_paths = ["src/**", "deploy.buildspec.yml", "buildspec.yml"]
  }

  build_buildspec_path  = "buildspec.yml"
  deploy_buildspec_path = "deploy.buildspec.yml"
}
