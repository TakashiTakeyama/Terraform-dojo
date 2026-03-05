# State 分割ガイド

このドキュメントは、Terraform state をどの単位で分割するかを決めるための実践ガイドです。

## 1. 基本方針

- 分割単位は `environment × service-stack` を基本とする
- 1 state = 1 サービス（またはサービス内の 1 サブ責務）
- 変更頻度・障害影響・承認フローの差があるものは分離する
- サービス境界を優先して切り、state の責務を明確にする

## 2. 推奨ディレクトリ構成（dev/stg/prod）

```text
terraform-dojo/
  modules/                        # 再利用モジュール（stateを持たない）
  terraform/
    env/
      dev/
        base/
        core-service/
        public-api/
        analytics/
        scheduled-tasks/
        batch-processor-base/
        batch-processor-runtime/
        batch-processor-pipeline/
      stg/
        # stg は prod と同じスタック境界を推奨
        ...
      prod/
        # サービス単位 + 必要時サブステート分割
        ...
```

各 stack ディレクトリをルートモジュールとし、`modules/` の再利用モジュールを呼び出す。
環境差分は `terraform/env/<env>/<stack>/terraform.tfvars` で管理する。
作成時は `terraform/env/_templates/stack-template.md` をテンプレートとして使う。

## 3. stack の責務例

- `core-service`: アプリ本体インフラ
- `public-api`: 外部連携 API
- `analytics`: 観測/分析系サービス
- `batch-processor-*`: 頻繁なコード更新を想定した分割スタック

## 4. backend key の命名規則

```text
project/<env>/<stack>/terraform.tfstate
```

例:

- `terraform-dojo/dev/base/terraform.tfstate`
- `terraform-dojo/stg/batch-worker-service/terraform.tfstate`
- `terraform-dojo/prod/batch-processor-pipeline/terraform.tfstate`

## 5. 分割判断チェックリスト

以下の 2 つ以上に当てはまる場合、state 分離を推奨:

- 更新頻度が他スタックと明らかに異なる
- apply 権限を別ロールに分けたい
- plan 差分が大きすぎてレビューが難しい
- 失敗時に影響範囲を局所化したい
- リソースライフサイクル（短命/長命）が異なる

## 6. 依存の扱い

- 原則は `data` ソースで参照し、state 直結を避ける
- `terraform_remote_state` が必要な場合は、契約（必須 output とバージョン更新手順）を明文化する
- 依存方向は一方向に保つ（例: `network -> app` で逆参照しない）

## 7. 運用ルール

- stack ごとに `terraform init/plan/apply` を実行する
- CI は stack 単位で plan/apply ジョブを分離する
- state 移行（`terraform state mv`）は専用手順書を用意して実施する

### 実行例（stg の app stack）

```bash
cd terraform/env/stg/batch-worker-service
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```
