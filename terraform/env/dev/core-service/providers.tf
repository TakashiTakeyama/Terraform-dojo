locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment_name
    Stack       = var.stack_name
    ManagedBy   = "terraform"
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.tags
  }
}
