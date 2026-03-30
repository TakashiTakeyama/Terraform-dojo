data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_codestarconnections_connection" "github" {
  name = var.github_connection_name
}
