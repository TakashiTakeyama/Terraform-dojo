# Terraform Dojo

このリポジトリは、AWS リソースを管理するための Terraform コードを含んでいます。様々な AWS サービス（EC2、S3、KMS、IAM、ECR、VPC、Lambda、CloudFront など）のプロビジョニングと管理を行うためのモジュール化されたコードが含まれています。

## 前提条件

- Terraform v1.9.5 以上
- AWS CLI がインストールされ、適切に設定されていること
- AWS 認証情報が設定されていること

## プロジェクト構造

```
terraform-dojo/
├── main.tf           # メインのTerraformコード
├── variables.tf      # 変数定義
├── providers.tf      # プロバイダー設定
├── versions.tf       # Terraformとプロバイダーのバージョン要件
├── locals.tf         # ローカル変数
├── modules/          # 再利用可能なモジュール
│   ├── aurora/       # Amazon Auroraデータベース用モジュール
│   ├── cloudfront/   # CloudFrontディストリビューション用モジュール
│   ├── ecr/          # ECRリポジトリ用モジュール
│   ├── iam/          # IAMユーザー・ロール用モジュール
│   ├── kms/          # KMSキー管理用モジュール
│   ├── lambda/       # Lambda関数用モジュール
│   ├── s3/           # S3バケット用モジュール
│   ├── ssm-ec2/      # SSM経由でのEC2管理用モジュール
│   └── vpc/          # VPC設定用モジュール
└── .gitignore        # Gitの除外ファイル設定
```

## 使用方法

### 初期化

```bash
terraform init
```

### 実行計画の確認

```bash
terraform plan -var-file=環境名.tfvars
```

### リソースのデプロイ

```bash
terraform apply -var-file=環境名.tfvars
```

### リソースの削除

```bash
terraform destroy -var-file=環境名.tfvars
```

## モジュール

このプロジェクトには以下のモジュールが含まれています：

- **ssm-ec2**: SSM 経由で EC2 インスタンスを管理するためのモジュール
- **kms**: KMS キーを作成・管理するためのモジュール
- **iam**: IAM ユーザーを作成するためのモジュール
- **s3**: S3 バケットを作成するためのモジュール
- **ecr**: ECR リポジトリを作成・管理するためのモジュール
- **vpc**: VPC を作成するためのモジュール
- **lambda**: コンテナイメージを使用して Lambda 関数をデプロイするためのモジュール
- **cloudfront**: CloudFront ディストリビューションを作成するためのモジュール
- **aurora**: Aurora データベースを管理するためのモジュール

## 変数設定

プロジェクトで使用される主な変数：

- `region`: デフォルトの AWS リージョン（デフォルト: ap-northeast-1）
- `vpc_name`: メイン VPC の名前
- `workspaces_name`: Terraform Cloud のワークスペース名
- その他、各モジュールに関連する変数

詳細な変数の説明は `variables.tf` ファイルを参照してください。

## 注意事項

- 本番環境にデプロイする前に、必ず `terraform plan` で変更内容を確認してください
- 機密情報は変数ファイルに直接記述せず、環境変数や安全な方法で管理してください
- 大規模な変更を行う場合は、影響範囲を十分に検討してください

## ライセンス

このプロジェクトは社内利用を目的としています。
