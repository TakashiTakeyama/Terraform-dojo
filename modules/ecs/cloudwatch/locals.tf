locals {
  region = "ap-northeast-1"
  name   = "ex-${basename(path.cwd)}"
  tags = {
    CostType  = local.name
    CreatedBy = "Terraform"
  }
}