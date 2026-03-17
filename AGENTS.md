# Terraform-dojo Agent Guidance

このリポジトリの Terraform コードを追加・修正する際のルールです。
すべての作業はこのファイルに従ってください。
詳細が必要な場合のみ、末尾のリンク先を参照してください。

## リポジトリ構成

```text
terraform-dojo/
  modules/                          # 再利用可能モジュール
  terraform/
    usecases/                      # stack の実体
    env/
      <env>/
        <stack>/                   # root module（state を持つ）
```

呼び出しの流れは `env -> usecases -> modules` です。

- `env`: backend / provider / version / 環境固有値を管理する root module
- `usecases`: 「このサービスで何を作るか」を定義する。stack に 1:1 で対応する
- `modules`: 「どう作るか」を汎用化した部品。複数の usecase から再利用する

### `usecase` と `module` の使い分け

- 1 つの stack でしか使わない → `usecase` に直接書く
- 2 つ以上の usecase で同じ構成が出てきた → `module` に切り出す
- 最初から再利用が明確な機能単位 → 最初から `module` にしてよい

## 標準ファイル構成

### root module（`terraform/env/<env>/<stack>/`）

- `backend.tf`: backend 設定
- `providers.tf`: provider 設定（`default_tags` 含む）
- `terraform.tf`: Terraform / Provider バージョン制約
- `main.tf`: usecase 呼び出しと環境固有値の注入
- `variables.tf`: 入力変数
- `locals.tf`: 命名、タグ、共通値
- `outputs.tf`: 出力

### usecase（`terraform/usecases/<stack>/`）

- `main.tf`: 主要リソース定義や module 呼び出し
- `variables.tf`: env から受け取る入力
- `locals.tf`: 共通値や入力正規化
- `outputs.tf`: 出力
- `terraform.tf`: バージョン制約
- 機能別ファイル（`ecs.tf`、`alb.tf`、`iam.tf` など）

### reusable module（`modules/<module-name>/`）

- `main.tf`: リソース定義
- `variables.tf`: 入力（`type` と `description` 必須）
- `locals.tf`: 共通値
- `outputs.tf`: 出力（最小限）
- `terraform.tf`: バージョン制約（下限指定）
- `README.md`: 利用例と契約

### ファイルの扱い

- `locals.tf` は中身がなくても先に作成してよい
- `data.tf`、`iam.tf` などは必要になった時点で追加する
- `versions.tf` ではなく `terraform.tf` を使う

## コーディングルール

### リソース定義

- `count` は 0 or 1 制御に使う
- `for_each` は入力と生成結果の対応が読み取れる場合に限定する
- 単純な文字列補間を隠すだけの `locals` は作らない
- 大きな設定オブジェクトを `locals` に押し込まない

### 入力値

- すべての `variable` に `type` と `description` を定義する
- 真偽値には `enable_`、`create_`、`is_`、`has_` の接頭辞を付ける
- 環境で実際に変わる値だけを入力にする
- `.auto.tfvars` は使わない

### 命名

- Terraform 識別子は `snake_case`
- AWS リソース名や `Name` タグは環境・用途が識別できる命名にする
- リポジトリ全体で命名規則を統一する

### ファイル分割

- ファイルは機能単位で分割する
- リソースタイプ別ではなく、変更理由と責務が追いやすい構成にする

### セキュリティ

- 機密情報をコードに書かない
- シークレットは Secrets Manager を使う
- IAM は最小権限。`*` は必要最小限
- IAM JSON は `aws_iam_policy_document` を使う
- Security Group は必要な宛先・ポートに絞る。全開放には理由を残す

### バージョン管理

- root module: 本番では厳密に固定する
- reusable module: 下限指定を基本とする

### 依存関係

- `terraform_remote_state` は原則使わない
- 既存リソース参照は `data` ソースや命名規則で解決する

### 外部モジュール

- 内容を理解できる場合に限って採用する
- バージョンを明示的に固定し、理由を残す

## やってはいけないこと

- `*.auto.tfvars` を使う
- `terraform_remote_state` を安易に増やす
- モジュール内で環境条件分岐する（`var.stage == "prod" ? ...`）
- 既存の `variable` / `output` を予告なく削除・改名する
- 機密情報を平文でコミットする
- 用途が曖昧な空ファイルを大量に作る

## 作業時の確認

```bash
terraform fmt -recursive
terraform validate
terraform plan
```

- 既存モジュールの入出力を変更する場合は、後方互換性を確認する
- 既存の挙動を壊すリネーム・削除には移行手順を文書化する

## テンプレート

新しい stack を作るときは以下を参照する:

- ファイル一覧: `terraform/env/_templates/stack-template.md`
- 実コード付きサンプル: `terraform/env/_templates/root-module-example.md`

## 詳細ドキュメント

判断に迷ったときのみ参照する:

- `docs/guidelines/index.md` — ガイドライン入口・読み方フロー
- `docs/guidelines/terraform-structure-design-guide.md` — 構成設計
- `docs/guidelines/terraform-coding-guideline.md` — コーディング規約
- `docs/guidelines/module-design-guideline.md` — モジュール設計
- `docs/guidelines/state-structure.md` — State 分割
- `docs/guidelines/review-checklist.md` — レビューチェックリスト
