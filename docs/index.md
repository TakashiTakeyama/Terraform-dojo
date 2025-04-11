# Terraform Dojo

AWS リソースのモジュールを管理するためのプロジェクトです。

## 概要

このプロジェクトは、AWS リソースを効率的に管理するための再利用可能な Terraform モジュールのコレクションです。
各モジュールは、特定の AWS サービスに特化しており、一貫した方法でリソースをプロビジョニングできます。

## 前提条件

- Terraform v1.9.5 以上
- AWS 認証情報が設定されている事

## 使い方

```bash
# 初期化
terraform init

# 実行計画の確認
terraform plan

# リソースの適用
terraform apply

# リソースの破棄
terraform destroy
```

## プロジェクト構造

```
terraform-dojo/
├── main.tf           # メインのTerraformコード
├── variables.tf      # 変数定義
├── providers.tf      # プロバイダー設定
├── versions.tf       # Terraformとプロバイダーのバージョン要件
├── locals.tf         # ローカル変数
├── modules/          # 再利用可能なモジュール
    ├── apigateway/   # API Gateway用モジュール
    ├── aurora/       # Amazon Auroraデータベース用モジュール
    ├── cloudfront/   # CloudFrontディストリビューション用モジュール
    └── ...           # その他のモジュール
```

各モジュールの詳細については、[モジュール概要](modules/index.md)を参照してください。
