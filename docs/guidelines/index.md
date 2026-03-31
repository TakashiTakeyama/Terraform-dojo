# コーディングガイドライン

Terraform-dojo で実装・レビューする際の基準をまとめたページです。

## まずどこから読むか

### 新しく Terraform 構成を考えるとき

1. [Terraform 構成設計ガイド](terraform-structure-design-guide.md)
2. [ディレクトリ・ファイル構成リファレンス](directory-file-reference.md)
3. [State 分割ガイド](state-structure.md)
4. [Terraform コーディング規約](terraform-coding-guideline.md)
5. [モジュール設計ガイド](module-design-guideline.md)
6. [シークレット情報の管理規約](secrets-management-guideline.md)

### 既存 stack を追加・修正するとき

1. [Terraform コーディング規約](terraform-coding-guideline.md)
2. [Environment Stacks](../../terraform/env/README.md)
3. [Root Module Example](../../terraform/env/_templates/root-module-example.md)
4. 必要に応じて [State 分割ガイド](state-structure.md)

### モジュールを追加・修正するとき

1. [モジュール設計ガイド](module-design-guideline.md)
2. [Terraform コーディング規約](terraform-coding-guideline.md)
3. 必要に応じて [Terraform 構成設計ガイド](terraform-structure-design-guide.md)

### レビューするとき

1. [Terraform レビューチェックリスト](review-checklist.md)
2. 必要に応じて各規約本文を参照する

## 一覧

- [Terraform 構成設計ガイド](terraform-structure-design-guide.md)
- [ディレクトリ・ファイル構成リファレンス](directory-file-reference.md)
- [Terraform コーディング規約](terraform-coding-guideline.md)
- [モジュール設計ガイド](module-design-guideline.md)
- [State 分割ガイド](state-structure.md)
- [シークレット情報の管理規約](secrets-management-guideline.md)
- [Terraform レビューチェックリスト](review-checklist.md)
- [CodePipeline（IaC）標準化の方針](codepipeline-standard-policy.md)（型 A/B/C。実装索引 `modules/codepipeline/README.md`、呼び出し例 `terraform/env/dev/`）
- [ECS アプリケーション CI/CD ガイドライン](app-ecs-cicd-guideline.md)（State 分割、Blue/Green デプロイ、CodePipeline フロー）
- [Lambda アプリケーション CI/CD ガイドライン](app-lambda-cicd-guideline.md)（State 分割、2 段階パイプライン、アーティファクトベースデプロイ）
