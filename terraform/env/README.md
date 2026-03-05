# Environment Stacks

このディレクトリは、環境ごとのルートモジュール（state 単位）を配置します。

## 構成

- `dev/`: 開発環境
- `stg/`: ステージング環境
- `prod/`: 本番環境

各環境ではサービス単位で state を分割します。

例:

- `base`
- `core-service`
- `public-api`
- `analytics`
- `scheduled-tasks`

同一サービス内で更新頻度や責務が異なる場合は、さらにサブステート分割します。

例:

- `batch-processor-base`
- `batch-processor-runtime`
- `batch-processor-pipeline`

## 運用ルール

- 各 stack ディレクトリで `terraform init/plan/apply` を実行する
- backend key は `project/<env>/<stack>/terraform.tfstate` を採用する
- stack 間参照は原則 `data` ソースを優先し、密結合を避ける
