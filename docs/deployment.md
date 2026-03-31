# デプロイ方法

このドキュメントでは、Terraform-dojo プロジェクトを使用して AWS リソースをデプロイする方法について説明します。

## 前提条件

デプロイを開始する前に、以下の前提条件を満たしていることを確認してください：

1. Terraform v1.9.5 以上がインストールされていること
2. AWS CLI がインストールされ、適切に設定されていること
3. 必要な AWS 権限が付与されていること

## AWS の認証設定

Terraform を使用するには、AWS の認証情報が正しく設定されている必要があります。以下のいずれかの方法で設定できます：

### 環境変数の設定

```bash
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
export AWS_DEFAULT_REGION="ap-northeast-1"
```

### AWS CLI 設定ファイルの使用

```bash
aws configure
```

### IAM ロールの使用

EC2 インスタンスや ECS コンテナ内で Terraform を実行する場合は、適切な IAM ロールを付与してください。

## デプロイ手順

### 1. Terraform の初期化

```bash
terraform init
```

これにより、必要なプロバイダーとモジュールがダウンロードされます。

### 2. 実行計画の確認

```bash
terraform plan
```

変更内容を確認し、予期しない変更がないことを確認してください。

### 3. リソースの適用

```bash
terraform apply
```

変更内容を確認して「yes」と入力すると、リソースが作成されます。

### 4. リソースの破棄

環境を削除する場合は以下のコマンドを実行します：

```bash
terraform destroy
```

## 複数環境の管理

環境差分はディレクトリ（`terraform/env/dev`, `terraform/env/stg`, `terraform/env/prod`）で管理します。  
必要に応じて `-var` で明示的に上書きしてください。

## State の分割戦略

- 基本は `environment × service-stack`（例: `dev/core-service`, `prod/public-api`）で管理します
- stack ごとに独立したルートモジュール（backend 設定付き）を作成します
- 詳細ルールは [State 分割ガイド](guidelines/state-structure.md) を参照してください

## 推奨ディレクトリ構成（dev/stg/prod）

```text
terraform/
  env/
    dev/
      base/
      core-service/
      public-api/
      analytics/
      scheduled-tasks/
    stg/
      base/
      core-service/
      public-api/
      batch-worker-infra/
      batch-worker-service/
      batch-worker-task/
      batch-worker-pipeline/
    prod/
      base/
      core-service/
      public-api/
      analytics/
      scheduled-tasks/
      batch-processor-base/
      batch-processor-runtime/
      batch-processor-pipeline/
```

各ディレクトリが 1 つの state を持つルートモジュールです。  
例えば `stg` の Worker Service だけを変更したい場合は `terraform/env/stg/batch-worker-service` で `plan/apply` します。
雛形は `terraform/env/` 配下に作成済みです。

## `base` と `core-service` の使い分け

- `base`: 複数サービスで共有される基盤リソースを管理
- `core-service`: 個別サービス実行に必要なリソースを管理
- 共通利用されるかどうかを境界判断の第一基準にする

## Terraform ワークスペースの使用

複数の環境を管理するもう一つの方法は、Terraform ワークスペースを使用することです：

```bash
# 新しいワークスペースの作成
terraform workspace new dev

# ワークスペースの切り替え
terraform workspace select prod

# 現在のワークスペースでの適用
terraform apply
```

## CI/CD パイプラインとの統合

GitHub Actions や AWS CodePipeline などの CI/CD ツールと Terraform を統合することで、インフラストラクチャの変更を自動化できます。

チームでの開発からリリースまでの一連のフロー（ブランチ戦略、PR ベースの plan/apply、Dev → Prod 段階デプロイ、安全策）については [Terraform リリースフローガイド](guidelines/terraform-release-flow.md) を参照してください。
