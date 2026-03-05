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

## 追加済みサンプル

- `base/`: 基盤スタックの最小サンプル
- `core-service/`: サービススタックの最小サンプル

どちらも `terraform_data` リソースを使った安全なテンプレートです。  
デフォルト値で `terraform init/plan` が実行でき、必要な値だけ `-var` で上書きできます。

## `base` と `core-service` の分け方

- `base` に置くもの:
  - 複数サービスから共通利用される土台リソース
  - 変更頻度が低く、影響範囲が広いリソース
  - 例: 共通ネットワーク、共通 IAM、共通 KMS、共通ログ基盤

- `core-service` に置くもの:
  - 単一サービスの実行に直接必要なリソース
  - デプロイ頻度が比較的高いリソース
  - 例: ECS/Lambda/API Gateway などサービス実行面

- 判断に迷う場合:
  - 他スタックでも参照されるなら `base`
  - そのサービスだけで閉じるなら `core-service`
