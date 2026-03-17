# Environment Stacks

このディレクトリは、環境ごとの root module（state 単位）を配置します。

## 基本構成

基本的な呼び出しの流れは `env -> usecases -> modules` です。

- `terraform/env/<env>/<stack>/`: 環境固有値を渡す root module。state を持つ
- `terraform/usecases/<stack>/`: stack の実体。環境に依存しないリソース定義を置く
- `modules/`: 複数の usecase から再利用する汎用部品

各 stack の root module は、対応する `terraform/usecases/` を呼び出し、環境固有値を注入します。

## 環境

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

## テンプレート

- 構成一覧: `_templates/stack-template.md`
- 実コード付きサンプル: `_templates/root-module-example.md`
