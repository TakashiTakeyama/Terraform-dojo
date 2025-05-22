# 既存 AWS リソースを **Import block** でコード化する手順

Terraform 1.5移行でimport blockを利用すれば**state ファイルを汚さずに** 既存リソースを `.tf` に取り込める

---

## 1 従来コマンドとの違い

|                | `terraform import` (旧) | **Import block** (1.5+)         |
| -------------- | ---------------------- | ------------------------------- |
| state 更新タイミング  | コマンド実行時に即書込み           | **apply 時**。plan 時は変更なし         |
| PR / CI での差分確認 | state が汚れるため危険         | **plan だけで差分を確認**できる            |
| やり直し負荷         | `state rm` など手間大       | block を削除すれば差分消える               |
| 最低限必要なコード      | resource + 必須属性        | resource + `import { id=… }` だけ |

---

## 2 フロー

### 2‑1 provider 設定

```hcl
# provider.tf
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5" }
  }
}
provider "aws" {
  region = "ap-northeast-1"
}
```

### 2‑2 import block を記述

```hcl
import {
  to = aws_ecs_cluster.hoge
  id = "cluster名/service名"
}
```

### 2‑3 generateコマンドで生成する

```bash
terraform plan -generate-config-out=generated.tf # localにファイルが生成される

```

---
