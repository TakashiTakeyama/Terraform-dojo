locals {
  aws_region  = "ap-northeast-1"
  name_prefix = "example-ecs-dev"

  github_connection_arn = "arn:aws:codeconnections:ap-northeast-1:000000000000:connection/REPLACE_ME"
  full_repository_id    = "your-org/your-ecs-app"
  branch_name           = "main"

  trigger = {
    branches   = ["main"]
    file_paths = ["app/**", "ci/**", "Dockerfile"]
  }

  build_buildspec_path  = "ci/docker-build.buildspec.yml"
  deploy_buildspec_path = "ci/ecs-deploy.buildspec.yml"
}
