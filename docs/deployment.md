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
terraform plan -var-file="環境名.tfvars"
```

変更内容を確認し、予期しない変更がないことを確認してください。

### 3. リソースの適用

```bash
terraform apply -var-file="環境名.tfvars"
```

変更内容を確認して「yes」と入力すると、リソースが作成されます。

### 4. リソースの破棄

環境を削除する場合は以下のコマンドを実行します：

```bash
terraform destroy -var-file="環境名.tfvars"
```

## 複数環境の管理

異なる環境（開発、ステージング、本番など）を管理するには、環境ごとに異なる`.tfvars`ファイルを作成します：

- `dev.tfvars` - 開発環境用
- `stg.tfvars` - ステージング環境用
- `prod.tfvars` - 本番環境用

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

詳細な設定例については、[GitHub Actions 設定例](https://github.com/yourusername/terraform-dojo/examples/github-actions)を参照してください。
