# stg environment stacks

`stg` は本番前検証のため、`prod` と同じスタック境界を基本とする。

## 推奨スタック例

- `base`
- `core-service`
- `public-api`
- `analytics`
- `scheduled-tasks`

## サブステート分割が必要な例

- `batch-worker-infra`
- `batch-worker-service`
- `batch-worker-task`
- `batch-worker-pipeline`
