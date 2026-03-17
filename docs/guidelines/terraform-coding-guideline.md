# Terraform コーディング規約

このドキュメントは、`Terraform-dojo` で Terraform コードを追加・修正する際の基本ルールを定義します。  
主な目的は、モジュール利用者が迷わず使えること、`terraform plan` の差分が予測しやすいこと、長期運用で破綻しにくいことです。

詳細なモジュール設計は `module-design-guideline.md`、state 分割は `state-structure.md`、レビュー観点は `review-checklist.md` を参照してください。

## 1. 基本原則

- 明示性を優先し、実際に作成されるリソースや設定値をコードから追いやすくする
- 抽象化は必要最小限に留め、読みやすさと保守性を優先する
- 変更の安全性を重視し、`plan` 差分の予測可能性を高く保つ
- 一時的に便利でも、将来の利用者やレビュアーが理解しにくい構成は避ける

## 2. 適用範囲

本リポジトリの Terraform コードは、次の 3 つの役割に分かれます。

- `root module`（`terraform/env/<env>/<stack>/`）: state を持ち、環境固有値を渡す。backend / provider / version を管理する
- `usecase`（`terraform/usecases/<stack>/`）: stack の実体。環境に依存しないリソース定義を置く。1 つの root module から呼ばれる
- `reusable module`（`modules/<module-name>/`）: 複数の usecase から再利用される汎用部品

基本的な呼び出しの流れは `env -> usecases -> modules` です。

### `usecase` と `module` の違い

- `usecase` は「ある stack で何を作るか」を定義する。特定のサービスや責務に紐づく
- `module` は「どう作るか」を部品化したもの。特定のサービスに依存しない

たとえば:

- `usecases/core-service/`: このサービスの ECS、ALB、Security Group などをまとめて定義する
- `modules/ecs-service/`: ECS Service + Task Definition + Auto Scaling を汎用的にまとめた部品。`core-service` からも `public-api` からも呼べる

判断基準:

- 1 つの stack でしか使わない → `usecase` に直接書く
- 2 つ以上の usecase で同じ構成が出てきた → `module` に切り出す
- 最初から再利用が明確な機能単位 → 最初から `module` にしてよい

### 2.1 標準ディレクトリ構成

Terraform コードは、役割ごとに以下のディレクトリに配置します。

```text
terraform-dojo/
  modules/                 # 再利用可能モジュール
  terraform/
    usecases/              # stack の実体
    env/
      <env>/
        <stack>/           # root module
```

- `modules/`: 複数の stack やプロジェクトから呼び出す再利用可能モジュールを置く
- `terraform/usecases/`: stack ごとの実体を置く
- `terraform/env/<env>/<stack>/`: state を持つ root module を置く
- 新しい構成を追加するときは、既存の責務境界を崩さない

### 2.2 標準ファイル構成

`root module`、`usecase`、`reusable module` では、基本となるファイルセットを揃えます。  
将来の差分を見通しやすくするため、まだ中身がなくても先に作成してよいファイルがあります。

#### `root module`

`terraform/env/<env>/<stack>/` では、原則として以下を配置します。

- `backend.tf`: backend 設定
- `providers.tf`: provider 設定
- `terraform.tf`: Terraform / Provider バージョン制約
- `main.tf`: モジュール呼び出しや主要定義
- `variables.tf`: root module の入力
- `locals.tf`: 命名、タグ、共通値の整理
- `outputs.tf`: 他ツールや利用者に渡す出力
- `README.md`: stack の目的と運用メモ。必要に応じて追加する

#### `usecase`

`terraform/usecases/<stack>/` では、原則として以下を配置します。

- `main.tf`: 主要なリソース定義や module 呼び出し
- `variables.tf`: env から受け取る入力
- `locals.tf`: 共通値や入力正規化
- `outputs.tf`: env や他ツールに返す出力
- `terraform.tf`: Terraform / Provider バージョン制約
- 機能別ファイル（`ecs.tf`、`alb.tf`、`iam.tf` など）: リソースが増えたら機能単位で分割する

#### `reusable module`

`modules/<module-name>/` では、原則として以下を配置します。

- `main.tf`: モジュールの主要定義
- `variables.tf`: 入力定義
- `locals.tf`: 共通値や入力正規化
- `outputs.tf`: 出力定義
- `terraform.tf`: Terraform / Provider バージョン制約
- `README.md`: 利用方法、入力、出力、注意点

#### ファイルの扱い

- `locals.tf` は、まだ `locals` を使っていなくても先に作成してよい
- 将来的に使うことが明らかな基本ファイルは、初期状態で揃えておくことを推奨する
- 一方で、用途が曖昧な空ファイルを増やしすぎない
- `data.tf`、`iam.tf`、`network.tf` などの機能別ファイルは、必要になった時点で追加する

## 3. リソース定義

### 3.1 `for_each` / `count`

- `count` は主に「作成する / しない」の 0 or 1 制御に使う
- `for_each` は、入力と生成結果の対応関係が読み取りやすい場合に限定して使う
- 単一リソースしか作らないのに、将来の拡張を見越して抽象化するのは避ける
- 動的生成によってレビュー時に実体が追いにくくなる場合は、明示的な定義を優先する

### 3.2 `locals`

- 重複削減、共通タグ、入力値の正規化など、意味のある共通化に使う
- 単純な文字列補間を隠すだけの `locals` は作らない
- 大きな設定オブジェクトを `locals` に押し込んで、実際のリソース定義を見えにくくしない

### 3.3 `data` ソース

- 既存リソースを安全に参照できるなら、`data` ソースを活用する
- 呼び出し側で容易に導出できる値まで、過剰に input として受け取らない
- ただし、`data` ソースを増やしすぎて暗黙依存が増える場合は、明示的な入力の方が適切なこともある

## 4. 入力値の設計

### 4.1 `variable`

- すべての入力変数に `type` と `description` を定義する
- 不正値を早期に防げる場合は `validation` を付ける
- 環境で実際に変わる値だけを入力にする
- 真偽値には `enable_`, `create_`, `is_`, `has_` などの接頭辞を付ける

### 4.2 `tfvars`

- `tfvars` は必要な場合のみ明示的に使う
- `.auto.tfvars` の常用は避け、意図しない自動読込を防ぐ
- 機密値を `tfvars` にコミットしない
- 環境差分をディレクトリ構成で表現できるなら、その方法を優先する

### 4.3 `output`

- 呼び出し側が本当に必要な値だけを公開する
- 名前は用途が明確に分かるものにする
- 内部実装の都合だけで `output` を増やさない

## 5. ファイル分割

- ファイルは機能単位で分割する
- 単に AWS リソース種別ごとに分けるより、変更理由と責務が追いやすい構成を優先する
- 関連する IAM、Security Group、監視設定などは、必要に応じて同じ機能単位にまとめてよい
- 巨大な単一ファイルと過剰な細分化の両方を避ける

## 6. 命名規則

- Terraform の識別子は `snake_case`
- 略語は一般的なものに限り、意味が伝わる名前を優先する
- AWS リソース名や `Name` タグは、環境や用途が識別しやすい命名にする
- リポジトリ全体で命名規則を統一し、同種のリソースで揺れを作らない

## 7. セキュリティ

- 機密情報を Terraform コードや平文ファイルに直接書かない
- シークレットはマネージドな secret store を利用する。AWS では `Secrets Manager` を推奨する
- IAM は最小権限を原則とし、`*` の利用は必要最小限にする
- IAM JSON は可能な限り `aws_iam_policy_document` を使って組み立てる
- Security Group は必要な宛先・ポートに絞り、全開放が必要な場合は理由を残す

## 8. バージョン管理

### 8.1 `root module`

- Terraform / Provider バージョンは、差分再現性を重視して厳しめに管理する
- 本番運用を担うルートモジュールでは、可能な限り厳密な固定を推奨する

### 8.2 `reusable module`

- 再利用可能モジュールは、利用者との互換性を意識した制約にする
- 下限指定を基本としつつ、実際のサポート範囲が曖昧にならないようにする
- バージョン制約の変更が利用者に与える影響を考慮する

## 9. 依存関係と state 参照

- State は用途や環境で分割し、責務を明確にする
- 詳細な分割方針は `state-structure.md` を参照する
- `terraform_remote_state` は state 間の密結合を生みやすいため原則として避ける
- 使う場合は、依存する `output`、更新手順、破壊的変更時の扱いを文書化する
- 既存リソース参照は、可能なら `data` ソースや命名規則で解決する

## 10. 外部モジュールの扱い

- 外部モジュールは、内容を理解できる場合に限って採用する
- 採用時は、ブラックボックス化、追従コスト、`plan` 予測性を確認する
- バージョンは明示的に制約し、理由を README や PR に残す
- 自前で実装した方が分かりやすく保守しやすい場合は、無理に導入しない

## 11. 例外ルール

- 規約から外れる実装が必要な場合は、理由が説明できることを前提とする
- 将来の利用者やレビュアーが判断に迷う箇所には、短いコメントや README を追加する
- 「一度だけ使うから」「とりあえず動くから」は例外理由として弱い

## 12. レビュー前チェック

変更内容に応じて、最低限以下を実施すること:

```bash
terraform fmt -recursive
terraform validate
terraform plan
```

必要に応じて `tflint`、`tfsec`、`checkov` なども実施する。
