# シークレット情報の管理規約

このドキュメントは、Terraform でシークレット情報（API キー、パスワード、トークンなど）を安全に管理するための基本方針と実装パターンを定義します。

## 1. 基本方針

Terraform によるシークレット情報の自動生成（`random_password` 等）は原則禁止とします。

**理由:** 自動生成された値は tfstate ファイルや実行ログに平文で記録されるため、セキュリティリスクが高まります。

**推奨される構成:** Terraform では「シークレットを格納する器（リソース）」のみを作成し、具体的な値は AWS マネジメントコンソールや CLI から手動で設定します。

```hcl
# ✅ 推奨: 器のみ作成
resource "aws_secretsmanager_secret" "api_key" {
  name        = "${var.stage}/${var.project}/api_key"
  description = "外部 API キー"
}

# ❌ 禁止: secret_version は定義しない（値が tfstate に記録される）
# resource "aws_secretsmanager_secret_version" "api_key" {
#   secret_id     = aws_secretsmanager_secret.api_key.id
#   secret_string = "..."
# }
```

**設定手順の参考:**

```bash
# AWS CLI での値投入
aws secretsmanager put-secret-value \
  --secret-id <secret-name> \
  --secret-string '{"key":"value"}'
```

## 2. AWS Secrets Manager と SSM Parameter Store の使い分け

シークレット情報の管理には、原則として AWS Secrets Manager を使用します。

### Secrets Manager を推奨する理由

- 作成時に初期値が不要で、「器だけ」を Terraform で作成できる
- IaC との相性が良い
- ローテーション機能を備えている
- アクセスポリシーによる細かな制御が可能

### SSM Parameter Store との違い

| 観点 | Secrets Manager | SSM Parameter Store |
|------|----------------|---------------------|
| 初期値 | 不要（器だけ作成可能） | 作成時に必須 |
| ローテーション | ネイティブサポート | なし |
| コスト | $0.40/月/シークレット | 無料（Standard） |
| IaC 相性 | 高い | 値の管理が課題 |
| 用途 | 機密情報 | 非機密な設定値 |

### 使い分けの判断基準

- **Secrets Manager**: API キー、パスワード、トークン等の機密情報
- **SSM Parameter Store**: URL、機能フラグ、ポート番号等の非機密設定

## 3. シークレットの命名規則

以下の命名パターンに従い、用途とスコープを明確にします。

### 3.1 `{env}/{service-name}`

**用途:** 特定のサービスでのみ使用し、ローテーション不要なもの

```text
dev/my-service
prod/my-service
```

**値の形式:** 複数のキーを JSON 形式でまとめて格納します。キー名は `snake_case` を使用します。

```json
{
  "slack_alert_channel": "xxxxx",
  "slack_alert_url": "https://hooks.slack.com/services/xxxxx"
}
```

### 3.2 `{env}/{service-name}/{rotation-target}`

**用途:** 特定のサービスで使用し、ローテーションが発生し得るもの

```text
dev/my-service/database
prod/my-service/api_key
```

**注意:** 用途としてまとまっている中に password が含まれる場合は、password を単体で切り出さず、関連する認証情報とセットで管理します。

```json
// ✅ 推奨: セットで格納
{
  "username": "db_user",
  "password": "db_password",
  "host": "db.example.com",
  "port": "5432"
}

// ❌ 非推奨: password を別シークレットとして分離
```

### 3.3 `{env}/shared`

**用途:** 複数のサービスで共通して利用し、ローテーション不要なもの

```text
dev/shared
prod/shared
```

### 3.4 `{env}/shared/{rotation-target}`

**用途:** 複数のサービスで共通利用し、定期的な更新が必要なもの

```text
dev/shared/datadog_api_token
prod/shared/datadog_api_token
```

## 4. コストとリソース管理

Secrets Manager は $0.40/月（1 シークレットあたり）のコストが発生します。同一のシークレット情報を複数のリソースに重複して作成することは避け、必要に応じて `shared` で管理してください。

```text
# ❌ 重複作成
prod/service-a/datadog_api_key
prod/service-b/datadog_api_key

# ✅ 共有シークレットに集約
prod/shared/datadog_api_key
```

## 5. 実装パターン

### 5.1 器の作成

```hcl
resource "aws_secretsmanager_secret" "database" {
  name        = "${var.stage}/${var.project}/database"
  description = "データベース接続情報"
}
```

### 5.2 値の参照

```hcl
data "aws_secretsmanager_secret_version" "database" {
  secret_id = aws_secretsmanager_secret.database.id
}
```

### 5.3 ECS タスク定義での参照

```json
{
  "name": "DB_PASSWORD",
  "valueFrom": "arn:aws:secretsmanager:ap-northeast-1:123456789012:secret:prod/my-service/database:password::"
}
```

## 6. IAM ポリシーの更新

新しいシークレットを追加する場合、アクセスする ECS サービス等の IAM ポリシーも更新が必要です。パスが既存ポリシーのスコープに含まれない場合、タスク起動時に権限エラーが発生します。

```hcl
data "aws_iam_policy_document" "secrets_access" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:${var.stage}/${var.project}/*",
      "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:${var.stage}/shared/*",
    ]
  }
}
```

## 7. リリース時の確認

リリース対象にシークレットが含まれる場合は、以下を確認してください:

- Secrets Manager にシークレットの器が作成済みであること
- 値が AWS コンソールまたは CLI で正しく投入されていること
- アクセス元の IAM ポリシーが更新されていること
