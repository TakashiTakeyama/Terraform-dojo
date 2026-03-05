# State 分割ガイド

このドキュメントは、Terraform state をどの単位で分割するかを決めるための実践ガイドです。

## 1. 基本方針

- 分割単位は `environment × stack` を基本とする
- 1 state = 1 責務（ネットワーク、ID 管理、アプリ実行基盤など）
- 変更頻度・障害影響・承認フローの差があるものは分離する

## 2. 推奨ディレクトリ構成

```text
terraform/
  env/
    dev/
      network/
      security/
      app/
    prod/
      network/
      security/
      app/
```

各 stack ディレクトリをルートモジュールとし、`modules/` の再利用モジュールを呼び出す。

## 3. backend key の命名規則

```text
project/<env>/<stack>/terraform.tfstate
```

例:

- `terraform-dojo/dev/network/terraform.tfstate`
- `terraform-dojo/prod/app/terraform.tfstate`

## 4. 分割判断チェックリスト

以下の 2 つ以上に当てはまる場合、state 分離を推奨:

- 更新頻度が他スタックと明らかに異なる
- apply 権限を別ロールに分けたい
- plan 差分が大きすぎてレビューが難しい
- 失敗時に影響範囲を局所化したい
- リソースライフサイクル（短命/長命）が異なる

## 5. 依存の扱い

- 原則は `data` ソースで参照し、state 直結を避ける
- `terraform_remote_state` が必要な場合は、契約（必須 output とバージョン更新手順）を明文化する
- 依存方向は一方向に保つ（例: `network -> app` で逆参照しない）

## 6. 運用ルール

- stack ごとに `terraform init/plan/apply` を実行する
- CI は stack 単位で plan/apply ジョブを分離する
- state 移行（`terraform state mv`）は専用手順書を用意して実施する
