# Terraform コーディング規約

このドキュメントは、`Terraform-dojo` で Terraform コードを追加・修正する際の基準を定義します。  
`aicentral-voice-infrastructure` の規約を参考にしつつ、`Terraform-dojo` の運用に合わせて調整しています。

## 1. 基本方針

- 明示性を優先し、レビュー時に実際の作成リソースが追える形で書く
- 複雑さは局所化し、モジュール利用者が理解しやすいインターフェースを維持する
- 変更の安全性を優先し、`plan` 差分の予測可能性を高く保つ

## 2. リソース定義

### 2.1 `for_each` / `count` の使い分け

- モジュールの再利用性向上に有効な場面では `for_each` / `count` を使用してよい
- ただし、1 つしか作らないリソースに対する過剰な抽象化は避ける
- `count` は「作成する / しない（0 or 1）」の制御で使う
- `for_each` は入力と作成リソースの対応関係が読み取れる場合に限定する

### 2.2 `locals` の利用

- 重複削減やタグ統一、入力値の正規化に使う
- 巨大な設定オブジェクトを `locals` に押し込み、実体を見えにくくする使い方は避ける

### 2.3 ファイル分割

- 機能単位で分割する（例: `network.tf`, `iam.tf`, `monitoring.tf`）
- 単にリソースタイプで分けるより、変更理由と差分が追える構成を優先する

## 3. モジュール設計

### 3.1 変数定義

- すべての入力変数は `type` と `description` を定義する
- 重要な値は `validation` を追加し、不正入力を早期に検出する
- 真偽値は `enable_`, `is_`, `create_` などの接頭辞を使う

### 3.2 tfvars の扱い

- 環境別設定は `-var-file` で明示的に読み込む
- 予期しない自動読込を避けるため、`.auto.tfvars` の常用は避ける
- 機密値を tfvars にコミットしない

### 3.3 outputs

- 本当に呼び出し側が必要な値だけを公開する
- 名前は用途が明確なものにする（例: `vpc_id`, `private_subnet_ids`）

## 4. 命名規則

- Terraform の識別子は `snake_case`
- AWS リソース名は環境・用途が判別できる命名にする
- 略語は一般的なものだけにし、意味が読み取れる名前を優先する

## 5. セキュリティ

- 機密情報は Terraform コードに直接書かない
- 秘密情報は AWS Secrets Manager などのマネージドな仕組みを利用する
- IAM ポリシーは最小権限を原則とし、`*` の乱用を避ける
- IAM JSON は可能な限り `aws_iam_policy_document` を使って組み立てる

## 6. バージョン管理

- Terraform / Provider バージョンは意図を持って固定または下限指定する
- ルートモジュールでは差分の再現性を重視し、可能な限り厳密に固定する
- モジュール側は互換性を意識して下限指定を基本とする

## 7. State と依存関係

- State は用途や環境で分割し、責務を明確にする
- `terraform_remote_state` は state 間の密結合になりやすいため、利用は慎重に判断する
- 既存リソース参照は、可能であれば `data` ソース（タグや命名規則）を優先する

### 7.1 推奨する分割単位

- まずは `environment × stack`（例: `dev/network`, `prod/security`）で分割する
- 更新頻度が明らかに異なるものは stack を分離する
- 破壊的変更の影響範囲が大きいもの（VPC、DB など）は独立 state を推奨する

### 7.2 分割の判断基準

以下のいずれかに当てはまる場合は、state の分離を検討する:

- 適用担当者や承認フローが異なる
- apply の失敗時に切り戻し単位を分けたい
- plan が大きくなりレビューしづらい
- 依存順序が固定され、同時変更が運用上のリスクになる

### 7.3 命名とキー設計

- backend key は `project/<env>/<stack>/terraform.tfstate` の形式を推奨する
- stack 名は責務ベースで命名する（`network`, `identity`, `data`, `app` など）
- 命名は長期運用前提で固定し、途中で頻繁に変更しない

詳細は `State 分割ガイド`（`docs/guidelines/state-structure.md`）を参照する。

## 8. レビュー前チェック

PR 作成前に最低限、以下を実施すること:

```bash
terraform fmt -recursive
terraform validate
terraform plan -var-file="<env>.tfvars"
```

必要に応じて `tflint` や `tfsec` も実施する。
