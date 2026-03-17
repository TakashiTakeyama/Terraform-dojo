# Terraform レビューチェックリスト

Terraform の PR を作成・レビューする際の最低限の確認項目です。  
規約本文とあわせて使い、見落としを減らすことを目的とします。

## 1. 実装

- リソースや設定値がコードから追いやすい
- `for_each` / `count` / `locals` が過剰な抽象化になっていない
- ファイル分割が機能単位で行われている
- 命名規則に一貫性がある

## 2. モジュール契約

- `variable` に `type` と `description` がある
- 必要な箇所に `validation` がある
- `output` が過剰に公開されていない
- 既存利用者に対する破壊的変更がない、または移行手順が明記されている

## 3. セキュリティ

- 機密情報がコードや tfvars に含まれていない
- IAM 権限が広すぎない
- Security Group の通信許可が広すぎない
- 全開放が必要な箇所には理由が残されている

## 4. 依存関係

- `terraform_remote_state` を安易に増やしていない
- `data` ソースや input の選び方が妥当
- state の責務境界が不自然になっていない

## 5. バージョンと外部依存

- Terraform / Provider のバージョン制約に意図がある
- 外部モジュールを使う場合、採用理由と version 制約が明確

## 6. 実行確認

変更内容に応じて、以下を確認する:

```bash
terraform fmt -recursive
terraform validate
terraform plan
```

必要に応じて `tflint`、`tfsec`、`checkov` なども実施する。
