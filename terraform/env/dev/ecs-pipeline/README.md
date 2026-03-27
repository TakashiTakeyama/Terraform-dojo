# ecs-pipeline

型 B・ECS CD のサンプル。[`pipeline-app-ecs`](../../../../modules/codepipeline/pipeline-app-ecs/) を使用。

## パイプライン構成

```mermaid
graph LR
  A[Source<br/>GitHub] --> B[Build<br/>Docker build → ECR push]
  B --> C[Deploy<br/>タスク定義登録 → サービス更新]
```

## ユースケース

- ECS Fargate/EC2 で動作するコンテナアプリを GitHub push をトリガーに **Docker ビルド → ECS デプロイ** まで自動化したい場合
- Build 段で Docker イメージをビルドし ECR に push、Deploy 段でタスク定義の登録とサービス更新を行う 2 段構成
- Build 段は Docker デーモンが必要なため `privileged_mode = true`（既定）、Deploy 段は不要なため `false`（既定）

## 使い方

`locals.tf` のプレースホルダと `data.tf` の IAM ポリシー（ECR リポジトリ ARN、ECS サービス ARN、タスク実行ロール ARN）を実際の値に書き換えてから `terraform plan`。
