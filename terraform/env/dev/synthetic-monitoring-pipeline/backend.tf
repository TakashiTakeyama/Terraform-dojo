terraform {
  backend "s3" {}
}

# terraform init \
#   -backend-config="bucket=<state-bucket>" \
#   -backend-config="key=terraform-dojo/dev/synthetic-monitoring-pipeline/terraform.tfstate" \
#   -backend-config="region=ap-northeast-1"
