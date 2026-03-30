# Terraform レビューチェックリスト

Terraform の PR を作成・レビューする際の最低限の確認項目です。  
規約本文とあわせて使い、見落としを減らすことを目的とします。

## 1. 実装

- リソースや設定値がコードから追いやすい
- `for_each` / `count` / `locals` が過剰な抽象化になっていない
- ファイル分割が機能単位で行われている
- 命名規則に一貫性がある（`${stage}-${project}-descriptor` パターン）
- `data` ソースが usecases 内で直接取得されている（env から不要な値を渡していない）
- 単純な文字列補間が `locals` に隠蔽されていない

## 2. モジュール契約

- `variable` に `type` と `description` がある
- 必要な箇所に `validation` がある
- `output` が過剰に公開されていない
- 既存利用者に対する破壊的変更がない、または移行手順が明記されている

## 3. セキュリティ

- 機密情報がコードや tfvars に含まれていない
- シークレットは Secrets Manager で器のみ作成し、`secret_version` を定義していない
- IAM ポリシーが `aws_iam_policy_document` で記述されている（JSON インライン不使用）
- IAM 権限が広すぎない（`*` の使用は最小限）
- Security Group の通信許可が広すぎない
- Security Group の egress が必要な宛先・ポートに制限されている
- 全開放が必要な箇所には理由がコメントで残されている
- Security Group の相互参照が `ingress_rule` / `egress_rule` リソースで実装されている（循環参照の回避）

## 4. 依存関係

- `terraform_remote_state` を安易に増やしていない
- `data` ソースや input の選び方が妥当
- state の責務境界が不自然になっていない
- シークレット追加時、アクセス元の IAM ポリシーが更新されている

## 5. バージョンと外部依存

- root module: Terraform / Provider バージョンが完全固定されている
- reusable module: `>=` で下限指定されている
- `.terraform-version` ファイルが配置されている
- 外部モジュールを使う場合、採用理由と version 制約が明確
- 外部モジュールは許容されたもの（VPC モジュール等）に限定されている

## 6. ECS パターン

- Auto Scaling 使用時に `lifecycle { ignore_changes = [desired_count] }` がある
- ヘルスチェックの `matcher` が具体的なステータスコード（`"200"` 等）になっている（`"200-399"` のような広い範囲は非推奨）

## 7. 実行確認

変更内容に応じて、以下を確認する:

```bash
terraform fmt -recursive
terraform validate
terraform plan
```

必要に応じて `tflint`、`tfsec`、`checkov` なども実施する。
