# Terraform Dojo

AWS リソースの module を管理

## 前提条件

- Terraform v1.9.5 以上
- AWS 認証情報が設定されている事

## プロジェクト構造

```
terraform-dojo/
├── main.tf           # メインのTerraformコード
├── variables.tf      # 変数定義
├── providers.tf      # プロバイダー設定
├── versions.tf       # Terraformとプロバイダーのバージョン要件
├── locals.tf         # ローカル変数
├── modules/          # 再利用可能なモジュール
│   ├── apigateway/   # API Gateway用モジュール
│   ├── aurora/       # Amazon Auroraデータベース用モジュール
│   ├── cloudfront/   # CloudFrontディストリビューション用モジュール
│   ├── ecr/          # ECRリポジトリ用モジュール
│   ├── ecs/          # ECSクラスター用モジュール
│   ├── iam/          # IAMユーザー・ロール用モジュール
│   ├── kms/          # KMSキー管理用モジュール
│   ├── lambda/       # Lambda関数用モジュール
│   ├── s3/           # S3バケット用モジュール
│   ├── ssm-ec2/      # SSM経由でのEC2管理用モジュール
│   ├── test/         # テスト用モジュール
│   └── vpc/          # VPC設定用モジュール
├── .terraform.lock.hcl # Terraformロックファイル
└── .gitignore        # Gitの除外ファイル設定
```

## モジュール

このプロジェクトには以下のモジュールが含まれています：

- **apigateway**: API Gateway リソースを管理するためのモジュール
- **aurora**: Aurora データベースを管理するためのモジュール
- **cloudfront**: CloudFront ディストリビューションを作成するためのモジュール
- **ecr**: ECR リポジトリを作成・管理するためのモジュール
- **ecs**: ECS クラスターとサービスを管理するためのモジュール
- **iam**: IAM ユーザーを作成するためのモジュール
- **kms**: KMS キーを作成・管理するためのモジュール
- **lambda**: コンテナイメージを使用して Lambda 関数をデプロイするためのモジュール
- **s3**: S3 バケットを作成するためのモジュール
- **ssm-ec2**: SSM 経由で EC2 インスタンスを管理するためのモジュール
- **test**: テスト目的のモジュール
- **vpc**: VPC を作成するためのモジュール
