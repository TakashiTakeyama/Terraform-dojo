# サンプル: スケジュール実行による S3 データ同期（Lambda）

対応図: [`diagram/awsdac/multi-account-scheduled-s3-sync.yml`](../../../diagram/awsdac/multi-account-scheduled-s3-sync.yml)

## このサンプルで使うサービスと役割

| サービス | このサンプルでの用途 |
|---|---|
| **Amazon S3** | `source` / `destination` の 2 バケット（図ではパートナー側・自社側のスタンドイン） |
| **Amazon EventBridge** | `cron` 相当のスケジュールで Lambda を定期起動 |
| **AWS Lambda** | ソースバケットのオブジェクトを宛先へ `copy_object`（ロジックは拡張前提） |
| **IAM** | Lambda 用実行ロール（S3 読み書き + CloudWatch Logs） |

## このサンプルで分かること

- EventBridge ルールで Lambda を定期起動する構成
- Lambda 実行ロールが S3 を読み書きする最小 IAM
- **同一 AWS アカウント内** の 2 バケットを同期（検証用）

## 本番に近づけるとき（マルチアカウント）

図の「Partner」「Integration」「Service」は別アカウントに分けることが多いです。

1. **Integration アカウント** にこのスタックを置く（Lambda + EventBridge）。
2. **Partner バケット** にバケットポリシーで Lambda ロール（またはクロスアカウントロール）への `s3:GetObject` を付与。
3. **Service バケット** 側に `s3:PutObject` を付与（同一アカウントならこのサンプルと同様）。
4. 複雑な場合は **Partner 側で AssumeRole** し、一時クレデンシャルでコピーする方式も検討する。

環境名による `if stage == "dev"` の条件分岐は [コーディング規約](../../../docs/guidelines/terraform-coding-guideline.md) に従い、明示的な変数で制御してください。

## 変数

| 変数 | 説明 |
|---|---|
| `stage` | 環境接頭辞（バケット名に使用） |
| `project` | プロジェクト接頭辞 |
| `schedule_expression` | EventBridge のスケジュール（既定: 毎日 UTC 2:00） |

## ファイル構成

- `main.tf` — S3、Lambda、EventBridge、IAM
- `lambda/handler.py` — 先頭ページのオブジェクトをコピーする最小処理（拡張前提）
