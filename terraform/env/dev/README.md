# dev environment stacks

環境配下はサービス単位で分割する。

## 推奨スタック例

- `base`
- `core-service`
- `public-api`
- `analytics`
- `scheduled-tasks`

## サブステート分割が必要な例

更新頻度が異なる場合は同一サービスをさらに分割する。

- `batch-processor-base`
- `batch-processor-runtime`
- `batch-processor-pipeline`
