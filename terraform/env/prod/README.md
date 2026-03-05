# prod environment stacks

`prod` は blast radius を最小化するため、サービス単位で state を分割する。

## 推奨スタック例

- `base`
- `core-service`
- `public-api`
- `analytics`
- `scheduled-tasks`

## サブステート分割が必要な例

デプロイ頻度の高いサービスは、`-base/-service/-pipeline/-task` などで段階分割する。
