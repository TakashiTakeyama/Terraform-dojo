# pipeline-app-lambda

**Lambda アプリ向け CD** 用の薄いラッパーです。内部で [`github-buildchain`](../github-buildchain/) を呼び、ステージを固定します。

- **Build**（`key = "build"`）… zip ビルド・テスト等
- **Deploy**（`key = "deploy"`）… `aws lambda update-function-code` 等（buildspec で定義）

型 B の特化版です。ECS やインフラ CD には別モジュール（[`pipeline-app-ecs`](../pipeline-app-ecs/)、[`pipeline-infra-tf`](../pipeline-infra-tf/)）を使ってください。

## 使い分け

| 用途 | 使うモジュール |
|------|----------------|
| Lambda 継続デリバリ | **本モジュール** |
| ECS（タスク定義・サービス更新） | `pipeline-app-ecs` |
| Terraform plan/apply | `pipeline-infra-tf` |
| 上記以外のカスタム段数 | `github-buildchain` を直接呼ぶ |

## 必須・推奨

- `name_prefix`、`github_connection_arn`、`full_repository_id`、`branch_name`
- 本番では `deploy_stage_iam_policy_json` に **Lambda 更新に必要な API のみ** を記述したポリシー JSON を渡すことを推奨

## 利用例

```hcl
module "lambda_cd" {
  source = "../../modules/codepipeline/pipeline-app-lambda"

  name_prefix = "my-svc-dev"

  github_connection_arn = var.github_connection_arn
  full_repository_id    = var.github_repository_id
  branch_name           = "main"

  trigger = {
    branches   = ["main"]
    file_paths = ["src/**", "deploy.buildspec.yml"]
  }

  deploy_stage_iam_policy_json = var.lambda_deploy_iam_policy_json
}
```

詳細オプションは `variables.tf` を参照（成果物バケット、KMS、タイムアウト等は `github-buildchain` と同様に透過）。
