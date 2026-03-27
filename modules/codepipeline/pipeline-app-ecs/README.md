# pipeline-app-ecs

**ECS アプリ向け CD** 用の薄いラッパーです。内部で [`github-buildchain`](../github-buildchain/) を呼び、ステージを固定します。

- **Build**（`key = "build"`）… Docker ビルド、ECR プッシュ等（**既定で `privileged_mode = true`**）
- **Deploy**（`key = "deploy"`）… タスク定義登録、サービス更新等（buildspec で定義）

Lambda 向けは [`pipeline-app-lambda`](../pipeline-app-lambda/)、インフラは [`pipeline-infra-tf`](../pipeline-infra-tf/) を使用してください。

## 使い分け

| 用途 | 使うモジュール |
|------|----------------|
| ECS 継続デリバリ | **本モジュール** |
| Lambda | `pipeline-app-lambda` |
| Terraform plan/apply | `pipeline-infra-tf` |

## 利用例

```hcl
module "ecs_cd" {
  source = "../../modules/codepipeline/pipeline-app-ecs"

  name_prefix = "my-api-dev"

  github_connection_arn = var.github_connection_arn
  full_repository_id    = var.github_repository_id
  branch_name           = "main"

  build_buildspec_path  = "ci/docker-build.buildspec.yml"
  deploy_buildspec_path = "ci/ecs-deploy.buildspec.yml"

  build_stage_iam_policy_json   = var.ecr_push_iam_policy_json
  deploy_stage_iam_policy_json  = var.ecs_deploy_iam_policy_json
}
```
