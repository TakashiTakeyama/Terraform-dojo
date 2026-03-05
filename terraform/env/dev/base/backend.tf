terraform {
  backend "s3" {}
}

# 例:
# terraform init \
#   -backend-config="bucket=<state-bucket>" \
#   -backend-config="key=terraform-dojo/dev/base/terraform.tfstate" \
#   -backend-config="region=ap-northeast-1"
