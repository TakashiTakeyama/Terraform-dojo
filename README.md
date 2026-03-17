# Terraform Dojo

AWS リソースの module を管理

## コーディング規約

Terraform の実装・レビュー時は、以下のガイドラインを参照してください。  
[Terraform コーディング規約](docs/guidelines/terraform-coding-guideline.md)

- [コーディングガイドライン一覧](docs/guidelines/index.md)
- [Terraform 構成設計ガイド](docs/guidelines/terraform-structure-design-guide.md)
- [モジュール設計ガイド](docs/guidelines/module-design-guideline.md)
- [State 分割ガイド](docs/guidelines/state-structure.md)
- [Terraform レビューチェックリスト](docs/guidelines/review-checklist.md)

## 読み方

目的ごとのおすすめ順は次のとおりです。

- 新しく Terraform 構成を考える: [Terraform 構成設計ガイド](docs/guidelines/terraform-structure-design-guide.md) -> [State 分割ガイド](docs/guidelines/state-structure.md) -> [Terraform コーディング規約](docs/guidelines/terraform-coding-guideline.md)
- 既存 stack を追加・修正する: [Terraform コーディング規約](docs/guidelines/terraform-coding-guideline.md) -> [Environment Stacks](terraform/env/README.md) -> [Root Module Example](terraform/env/_templates/root-module-example.md)
- モジュールを追加・修正する: [モジュール設計ガイド](docs/guidelines/module-design-guideline.md) -> [Terraform コーディング規約](docs/guidelines/terraform-coding-guideline.md)
- レビューする: [Terraform レビューチェックリスト](docs/guidelines/review-checklist.md) -> 必要に応じて各規約本文

## 環境スタック

環境別・stack別のルートモジュール運用は以下を参照してください。  
[Environment Stacks](terraform/env/README.md)

## 前提条件

- Terraform v1.9.5 以上
- AWS 認証情報が設定されている事

## プロジェクト構造

```
terraform-dojo/
├── modules/                    # 再利用可能なモジュール
│   ├── apigateway/
│   ├── aurora/
│   ├── cloudfront/
│   ├── ecr/
│   ├── ecs/
│   ├── iam/
│   ├── kms/
│   ├── lambda/
│   ├── s3/
│   ├── ssm-ec2/
│   ├── test/
│   ├── tgw/
│   └── vpc/
└── terraform/
    ├── usecases/              # stack の実体
    └── env/                   # 環境別の root module（state分割）
        ├── dev/
        ├── stg/
        └── prod/
```

基本構成は `env -> usecases -> modules` です。

- `env`: backend / provider / version / 環境固有値を持つ root module
- `usecases`: stack の実体
- `modules`: 複数 usecase で再利用する部品

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
- **tgw**: Transit Gateway と VPC 接続用のモジュール
- **vpc**: VPC を作成するためのモジュール
