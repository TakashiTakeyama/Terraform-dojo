# Root Module Example

`terraform/env/<env>/<stack>/` を新しく作るときの最小サンプルです。  
このリポジトリでは、`versions.tf` ではなく `terraform.tf` に Terraform / Provider の要件をまとめます。

想定ディレクトリ:

```text
terraform/env/dev/core-service/
  backend.tf
  providers.tf
  terraform.tf
  variables.tf
  locals.tf
  main.tf
  outputs.tf
```

## `backend.tf`

```hcl
terraform {
  backend "s3" {}
}

# 例:
# terraform init \
#   -backend-config="bucket=<state-bucket>" \
#   -backend-config="key=terraform-dojo/dev/core-service/terraform.tfstate" \
#   -backend-config="region=ap-northeast-1"
```

## `terraform.tf`

```hcl
terraform {
  required_version = ">= 1.9.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.84.0"
    }
  }
}
```

## `variables.tf`

```hcl
variable "project_name" {
  description = "プロジェクト名"
  type        = string
  default     = "terraform-dojo"
}

variable "environment_name" {
  description = "環境名"
  type        = string
  default     = "dev"
}

variable "stack_name" {
  description = "スタック名"
  type        = string
  default     = "core-service"
}

variable "region" {
  description = "AWS リージョン"
  type        = string
  default     = "ap-northeast-1"
}
```

## `locals.tf`

```hcl
locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment_name
    Stack       = var.stack_name
    ManagedBy   = "terraform"
  }
}
```

## `providers.tf`

```hcl
provider "aws" {
  region = var.region

  default_tags {
    tags = local.tags
  }
}
```

## `main.tf`

まずは `usecases` を呼び出す構成を基本とします。

```hcl
module "core_service" {
  source = "../../../usecases/core-service"

  project_name     = var.project_name
  environment_name = var.environment_name
  stack_name       = var.stack_name
}
```

まだ `usecases` を作らない小さな検証では、root module で直接リソースを書いても構いません。

```hcl
resource "terraform_data" "stack_marker" {
  input = {
    project     = var.project_name
    environment = var.environment_name
    stack       = var.stack_name
    purpose     = "core service sample"
  }
}
```

## `outputs.tf`

```hcl
output "stack_name" {
  description = "スタック名"
  value       = var.stack_name
}
```

## 補足

- `locals.tf` は、現時点で `locals` を使っていなくても先に作成してよい
- `providers.tf` と `terraform.tf` は役割を分けておく
- 実運用では、`main.tf` には環境固有値の注入と usecase 呼び出しを中心に置く
- 本番環境では、バージョン制約を `>=` ではなく厳密な固定（例: `"1.9.5"`, `"5.84.0"`）にすることを推奨する。上のサンプルは開発・検証向けの下限指定
