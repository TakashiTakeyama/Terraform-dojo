# pipeline-infra-tf

**インフラ IaC（Terraform）向け** の薄いラッパーです。型 C の第一選択として、**アプリ用パイプライン（Lambda/ECS）とは別 root・別 state** で呼び出すことを想定しています。

- **Plan**（`key = "plan"`）
- **Apply**（`key = "apply"`）

内部実装は [`github-buildchain`](../github-buildchain/) と同一です。手動承認ステージはモジュール外で合成してください。

## 使い分け

| 用途 | 使うモジュール |
|------|----------------|
| インフラ plan/apply | **本モジュール** |
| Lambda | `pipeline-app-lambda` |
| ECS | `pipeline-app-ecs` |

## 利用例

```hcl
module "iac_cd" {
  source = "../../modules/codepipeline/pipeline-infra-tf"

  name_prefix = "platform-tf-dev"

  github_connection_arn = var.github_connection_arn
  full_repository_id    = var.infra_repository_id
  branch_name           = "main"

  trigger = {
    branches   = ["main"]
    file_paths = ["terraform/**", "ci/terraform-*.buildspec.yml"]
  }

  plan_stage_iam_policy_json  = var.tf_plan_iam_policy_json
  apply_stage_iam_policy_json = var.tf_apply_iam_policy_json
}
```
