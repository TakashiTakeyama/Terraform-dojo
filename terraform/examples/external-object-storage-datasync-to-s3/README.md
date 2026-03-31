# サンプル: DataSync による S3 バケット間コピー

対応図: [`diagram/awsdac/external-object-storage-datasync-to-s3.yml`](../../../diagram/awsdac/external-object-storage-datasync-to-s3.yml)

## このサンプルで使うサービスと役割

| サービス | このサンプルでの用途 |
|---|---|
| **Amazon S3** | DataSync の **ソース** と **宛先** の両方にバケットを用意（検証用。本番ではソースを外部互換ストレージ側に置き換える想定） |
| **AWS DataSync** | ソース／宛先 **ロケーション** と **タスク** を定義し、バケット間のコピー経路を構成 |
| **IAM** | DataSync が各バケットにアクセスするためのロール（`datasync.amazonaws.com` への信頼） |

## このサンプルで分かること

- DataSync 用 IAM ロール（`datasync.amazonaws.com` への信頼）
- `aws_datasync_location_s3` をソース・宛先に指定した `aws_datasync_task`
- **同一リージョン内の 2 つの S3 バケット** をコピー（検証用）

## 外部の S3 互換ストレージへ差し替えるには

図の左側は「S3 互換の外部オブジェクトストレージ」を表します。AWS 上では多くの場合、次のいずれかになります。

1. **`aws_datasync_location_object_storage`**  
   自前ホストや他クラウドの S3 互換エンドポイント。  
   **DataSync エージェント** の配置要件があることが多いので、[DataSync のドキュメント](https://docs.aws.amazon.com/datasync/) で対象環境を確認する。

2. **別 AWS アカウントの S3**  
   このサンプルと同様に `aws_datasync_location_s3` でよいことが多い。バケットポリシーとロール権限でクロスアカウントを許可する。

ソースロケーションを差し替えたうえで、`aws_datasync_task` の `source_location_arn` を差し替えればよい。

## 変数

| 変数 | 説明 |
|---|---|
| `stage` / `project` | リソース名の接頭辞 |
| `enable_task` | `true` でタスク作成。検証でロケーションだけ先に作りたい場合は `false` |

## 運用上の注意

- 初回は **タスク実行を手動** し、想定どおりコピーされるか確認してからスケジュールを検討する。
- 大量データでは転送オプション（帯域、検証モード）を [options ブロック](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/datasync_task#options) で調整する。
