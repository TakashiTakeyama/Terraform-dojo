terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }

  # backend "s3" {
  #   bucket = "your-tfstate-bucket"
  #   key    = "lambda-pipeline/terraform.tfstate"
  #   region = "ap-northeast-1"
  # }
}
