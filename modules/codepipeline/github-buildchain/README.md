# github-buildchain

GitHub（CodeStar Connections / CodeConnections）をソースとし、**Source → CodeBuild（1 段以上）** という骨格の CodePipeline（V2）を構築するモジュールです。

**用途が決まっている場合**は、ステージ key を固定したラッパーの利用を推奨します（レビュー・命名が揃うため）。

| 用途 | ラッパー |
|------|----------|
| Lambda CD（build → deploy） | [`pipeline-app-lambda`](../pipeline-app-lambda/) |
| ECS CD（build → deploy） | [`pipeline-app-ecs`](../pipeline-app-ecs/) |
| インフラ IaC（plan → apply） | [`pipeline-infra-tf`](../pipeline-infra-tf/) |

段数の増減や独自ステージ名が必要なときだけ、本モジュールを直接呼び出してください。

[CodePipeline（IaC）標準化の方針](../../../docs/guidelines/codepipeline-standard-policy.md) に沿い、識別子はすべて変数で渡します。型 A / B / C の整理は [親 README](../README.md) と方針 §4 を参照してください。

---

## 型 A / 型 B / 型 C（このモジュールとの関係）

| 型 | 意味 | このモジュールでの使い方 |
|----|------|---------------------------|
| **A** | ビルドのみ（成果物のリリースは別） | `codebuild_stages` に **1 要素**（例: `key = "build"`） |
| **B** | ビルド → デプロイ（アプリを AWS に反映） | `codebuild_stages` に **2 要素以上**。後段に `additional_iam_policy_json` でデプロイ API 権限を付与 |
| **C** | インフラ（plan / apply 等） | **アプリの A/B と別の Terraform root・別 state・別 `name_prefix`** で本モジュールを呼ぶ。同じ `.tf` にアプリ用パイプラインと混在させない（型として別ライン） |

型 C も CodePipeline + CodeBuild の組み合わせは同じだが、**標準では「インフラ CD」用のスタックだけを分ける**。buildspec・IAM・リポジトリ上のパスは IaC 用に特化させる。

---

## 必須の入力

- `name_prefix` … リソース名の接頭辞
- `github_connection_arn` … 事前に作成した接続の ARN
- `full_repository_id` … `owner/repo`
- `branch_name`
- `codebuild_stages` … 少なくとも 1 ステージ

成果物用 S3 は `create_artifact_bucket = true`（デフォルト）で新規作成するか、`false` のとき `artifact_s3_bucket_id` で既存を指定します。

---

## 利用例（型 A: ビルドのみ）

```hcl
module "ci_build" {
  source = "../../modules/codepipeline/github-buildchain"

  name_prefix = "myapp-dev"

  github_connection_arn = var.github_connection_arn
  full_repository_id    = var.github_repository_id
  branch_name           = "main"

  codebuild_stages = [
    {
      key  = "build"
      name = "Build"
      # リポジトリの buildspec.yml を使う場合は buildspec_inline を省略
      buildspec_path = "buildspec.yml"
    }
  ]
}
```

---

## 利用例（型 B: ビルド → デプロイ）

```hcl
module "ci_cd" {
  source = "../../modules/codepipeline/github-buildchain"

  name_prefix = "myapp-dev"

  github_connection_arn = var.github_connection_arn
  full_repository_id    = var.github_repository_id
  branch_name           = "main"

  codebuild_stages = [
    {
      key            = "build"
      name           = "Build"
      buildspec_path = "buildspec.yml"
    },
    {
      key            = "deploy"
      name           = "Deploy"
      buildspec_path = "deploy.buildspec.yml"
      # デプロイ用 API 権限のみここに注入（最小権限の JSON を推奨）
      additional_iam_policy_json = var.deploy_stage_iam_policy_json
    }
  ]
}
```

---

## 利用例（型 C: インフラのみ — 別 root で呼び出す）

アプリ用の `module "ci_cd"` と**同じファイルに書かない**。別ディレクトリ（例: `terraform/env/infra-pipeline/`）で:

```hcl
module "iac_pipeline" {
  source = "../../modules/codepipeline/github-buildchain"

  name_prefix = "myplatform-tf-dev"

  github_connection_arn = var.github_connection_arn
  full_repository_id    = var.github_infra_repository_id
  branch_name           = "main"

  codebuild_stages = [
    {
      key            = "plan"
      name           = "Plan"
      buildspec_path = "ci/plan.buildspec.yml"
    },
    {
      key            = "apply"
      name           = "Apply"
      buildspec_path = "ci/apply.buildspec.yml"
      additional_iam_policy_json = var.iac_apply_stage_iam_policy_json
    }
  ]
}
```

`buildspec` の中身・承認ゲート（手動承認ステージ等）は方針どおりモジュール外で足すか、別リソースと合成する。

---

## V2 トリガー（推奨）

`trigger` 変数で、ブランチ・パス・タグの組み合わせでパイプラインの起動条件を絞り込めます。  
**`trigger` を指定すると `DetectChanges` は自動で `false` に上書き**されるため、`source_detect_changes` の明示指定は不要です。

```hcl
# 例: main ブランチかつ src/ 配下の変更時のみ起動
trigger = {
  branches   = ["main"]
  file_paths = ["src/**"]
}

# 例: タグプッシュで起動（セマンティックバージョン）
trigger = {
  tags = ["v[0-9]*.[0-9]*.[0-9]*"]
}
```

`trigger = null`（既定）のときは `source_detect_changes`（既定 `true`）に任せます。  
特定ブランチのみ起動させたい本番ユースケースでは `trigger` の利用を強く推奨します。

---

## ステージ間の変数渡し（namespace）

`codebuild_stages[].namespace` を指定すると、そのステージのアクションに namespace が設定され、後続ステージの buildspec 内から `#{<namespace>.EXPORTED_VAR}` で参照できます。

```hcl
codebuild_stages = [
  {
    key       = "plan"
    name      = "Plan"
    namespace = "PlanOutput"
    buildspec_inline = <<-EOT
      version: 0.2
      env:
        exported-variables:
          - IMAGE_TAG
      phases:
        build:
          commands:
            - export IMAGE_TAG=$(git rev-parse --short HEAD)
    EOT
  },
  {
    key            = "deploy"
    name           = "Deploy"
    buildspec_path = "deploy.buildspec.yml"
    # deploy.buildspec.yml 内で #{PlanOutput.IMAGE_TAG} を使用可能
  }
]
```

---

## 主なオプション

| 変数 | 既定 | 説明 |
|------|------|------|
| `trigger` | `null` | V2 トリガー（ブランチ・パス・タグ）。詳細は上記参照 |
| `artifact_lifecycle_expiration_days` | `30` | 成果物の有効期限（日）。`0` でライフサイクル無効 |
| `source_output_artifact_format` | `CODE_ZIP` | `CODEBUILD_CLONE_REF` も指定可 |
| `artifact_store_kms_key_arn` | `null` | 成果物の KMS 暗号化。バケット新規作成時は SSE も自動設定 |
| `codebuild_managed_policy_arns` | `[]` | 全 CodeBuild ロールへの共通 AWS 管理ポリシー |
| `pipeline_additional_iam_policy_json` | `null` | パイプライン本体ロールへの追加ポリシー |
| `execution_mode` | `QUEUED` | `SUPERSEDED`（後続が前回を上書き）、`PARALLEL`（複数実行を独立動作）も指定可 |

---

## 手動承認・通知

本モジュールには含めていません。方針どおり、別コンポジションまたは別リソースで EventBridge / Manual Approval ステージを足してください。

---

## 既知の制限

| 制限 | 回避策 |
|------|--------|
| **環境変数は PLAINTEXT のみ**。`codebuild_stages[].environment_variables` は `map(string)` で `type = "PLAINTEXT"` 固定。`PARAMETER_STORE` / `SECRETS_MANAGER` を使いたい場合はこのモジュールでは対応できない | buildspec 内で `aws ssm get-parameter` / `aws secretsmanager get-secret-value` を呼ぶか、`environment_variables` の型を `map(object({ value = string, type = optional(string, "PLAINTEXT") }))` に拡張する |
| **1 ステージ = 1 アクション（並列実行非対応）**。別プロジェクトのパイプラインでは同一ステージ内で複数 Action を `run_order` で並列実行している例もあるが、本モジュールは 1 ステージ 1 Action に固定 | 独立して並列化できるビルド・差分確認などは別ステージに分割するか、モジュールを拡張する |
| **`before_entry` 条件スキップ非対応**。差分なし時の早期終了など、参考実装の条件付きステージスキップは実装していない | buildspec 内で `aws codepipeline stop-pipeline-execution` を呼ぶか、Lambda / EventBridge で制御する |

---

## ファイル構成

| ファイル | 内容 |
|----------|------|
| `codepipeline.tf` | `aws_codepipeline` |
| `codebuild.tf` | `aws_codebuild_project`、ロググループ |
| `s3.tf` | 成果物バケット（作成時） |
| `iam_pipeline.tf` / `iam_codebuild.tf` | IAM |
| `variables.tf` / `locals.tf` / `outputs.tf` / `data.tf` / `terraform.tf` | 入出力・データソース・バージョン制約 |
