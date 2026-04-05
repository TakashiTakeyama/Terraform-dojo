# Terraform Dojo

AWS リソースのモジュールを管理するためのプロジェクトです。

## 読み方

Terraform 実装時の基準は [コーディングガイドライン](guidelines/index.md) を参照してください。

- 新しく Terraform 構成を考える: [Terraform 構成設計ガイド](guidelines/terraform-structure-design-guide.md) -> [State 分割ガイド](guidelines/state-structure.md) -> [Terraform コーディング規約](guidelines/terraform-coding-guideline.md)
- 既存 stack を追加・修正する: [Terraform コーディング規約](guidelines/terraform-coding-guideline.md) -> [Environment Stacks](../terraform/env/README.md)
- モジュールを追加・修正する: [モジュール設計ガイド](guidelines/module-design-guideline.md) -> [Terraform コーディング規約](guidelines/terraform-coding-guideline.md)
- レビューする: [Terraform レビューチェックリスト](guidelines/review-checklist.md)

## ガイド一覧

- [AWS アプリケーション基盤の選定基準](architecture/aws-application-platform-decision-guide.md)
- [AWS Web 配信・SSR の考え方](architecture/aws-web-hosting-decision-guide.md)
- [Terraform 構成設計ガイド](guidelines/terraform-structure-design-guide.md)
- [Terraform コーディング規約](guidelines/terraform-coding-guideline.md)
- [モジュール設計ガイド](guidelines/module-design-guideline.md)
- [State 分割ガイド](guidelines/state-structure.md)
- [Terraform レビューチェックリスト](guidelines/review-checklist.md)

## 概要

このプロジェクトは、再利用可能な Terraform モジュールと、環境ごとの root module を管理するためのリポジトリです。
基本構成は `env -> usecases -> modules` です。

## 前提条件

- Terraform v1.9.5 以上
- AWS 認証情報が設定されている事

## 使い方

各 stack ディレクトリに移動して実行します。

```bash
cd terraform/env/dev/core-service
terraform init
terraform plan
terraform apply
```

詳細は [Environment Stacks](../terraform/env/README.md) を参照してください。

## プロジェクト構造

```
terraform-dojo/
├── modules/                  # 再利用可能モジュール
└── terraform/
    ├── usecases/            # stack の実体
    └── env/                 # 環境別の root module
```

各モジュールの詳細については、[モジュール概要](modules/index.md) を参照してください。
