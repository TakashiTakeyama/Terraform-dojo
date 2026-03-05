# Terraform-dojo Agent Guidance

## 目的

このリポジトリは、再利用可能な Terraform モジュールを提供することを目的としています。  
変更時は「モジュール利用者が迷わないこと」と「plan 差分が予測しやすいこと」を最優先にしてください。

## 必須参照

- コーディング規約: `docs/guidelines/terraform-coding-guideline.md`

## 作業ルール

- Terraform 変更時は `terraform fmt -recursive` と `terraform validate` を実施する
- 影響範囲が大きい変更は、モジュールの入出力（variables/outputs）の後方互換性を意識する
- 機密情報はコードへ埋め込まず、Secrets Manager などの安全な手段を使う
- 既存の挙動を壊しうるリネーム・削除を行う場合は、移行手順もドキュメント化する
