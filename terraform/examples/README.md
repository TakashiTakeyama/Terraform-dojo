# アーキテクチャパターン別サンプル

[diagram/awsdac/](../../diagram/awsdac/) の構成図に対応する **参考用** Terraform です。  
そのまま `apply` できる最小構成にしてあり、本番利用前に必ず要件に合わせて改修してください。

**サービスと用途の一覧** は [`diagram/README.md`](../../diagram/README.md) の節「各ダイアグラムの AWS（関連）サービスと用途」にまとめています。

| サンプル | 対応図 | 主な AWS サービス | 用途（このリポジトリのサンプルで示していること） |
|---|---|---|---|
| [multi-account-scheduled-s3-sync](./multi-account-scheduled-s3-sync/) | `multi-account-scheduled-s3-sync.yml` | S3, EventBridge, Lambda, IAM | スケジュール起動で **同一アカウント内の 2 バケット** をコピー（本番ではクロスアカウント・Hub アカウント構成へ拡張） |
| [external-object-storage-datasync-to-s3](./external-object-storage-datasync-to-s3/) | `external-object-storage-datasync-to-s3.yml` | S3, DataSync, IAM | **S3 ロケーション同士** の DataSync タスク（ソースを object storage ロケーションに差し替えれば図の外部ストレージ取り込みに近づく） |

## 使い方

```bash
cd terraform/examples/<pattern-name>
terraform init -backend=false   # または backend なしのまま init
terraform plan
```

バックエンドはローカル state のままです。チーム運用では S3 backend へ差し替えてください。
