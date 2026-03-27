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

## CodePipeline（本番）

`dev` と同じスタック名（例: `lambda-pipeline/`）を `terraform/env/prod/` に置き、`locals.tf`・`backend` を本番用に差し替える。テンプレは [`dev/README.md`](../dev/README.md) の CodePipeline 表を参照。
