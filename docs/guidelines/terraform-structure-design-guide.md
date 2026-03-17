# Terraform 構成設計ガイド

このドキュメントは、Terraform プロジェクトを一から設計する際に、どのようにディレクトリと state を分けるかを決めるためのガイドです。  
単にファイルを置く場所を決めるだけではなく、変更頻度、責務、デプロイ単位を踏まえて、長期運用しやすい構成を作ることを目的とします。

## 1. まず決めること

Terraform の構成を考え始めるときは、最初に次の 3 つを決めます。

1. どの単位で `plan` / `apply` したいか
2. どのリソースを共有基盤として扱うか
3. どの変更を独立してデプロイしたいか

この 3 つが曖昧なままディレクトリを切ると、あとから state 分割や責務整理が難しくなります。

## 2. 推奨する全体構成

Terraform-dojo では、基本的に次の 3 層構成を推奨します。

```text
terraform-dojo/
  modules/
    <module-name>/
  terraform/
    usecases/
      <usecase-name>/
    env/
      dev/
        <stack>/
      stg/
        <stack>/
      prod/
        <stack>/
```

- `modules/`: 再利用可能な内部モジュール
- `terraform/usecases/`: ある stack の実体となる構成
- `terraform/env/<env>/<stack>/`: state を持つ root module

## 3. 各ディレクトリの責務

### 3.1 `env`

- 環境ごとの root module を置く
- backend、provider、version、環境固有値、usecase 呼び出しを管理する
- 1 ディレクトリ = 1 state = 1 apply 単位を基本とする

### 3.2 `usecases`

- 各 stack の実体となる Terraform コードを置く
- 「どのリソース群を 1 つの責務として扱うか」を表現する
- 環境差分はなるべく input で受け取り、構造自体は環境間で揃える

### 3.3 `modules`

- 複数の usecase から再利用したい機能単位の部品を置く
- AWS リソース 1 個ごとではなく、利用者に意味のある機能単位で切る
- state は持たない

### 3.4 `usecases` と `modules` の違い

`usecases` と `modules` は役割が異なります。

- `usecase` は「**何を作るか**」を定義する。特定のサービスや stack に紐づく
- `module` は「**どう作るか**」を部品化したもの。特定のサービスに依存しない

具体例:

```text
usecases/
  core-service/          # このサービスの ECS + ALB + SG をまとめて定義
  public-api/            # 外部 API の API Gateway + Lambda をまとめて定義

modules/
  ecs-service/           # ECS Service + Task Definition + Auto Scaling の汎用部品
  alb/                   # ALB + Listener + Target Group の汎用部品
```

`usecases/core-service/` は `modules/ecs-service/` と `modules/alb/` を呼び出せます。  
`usecases/public-api/` も同じ `modules/ecs-service/` を別の設定で呼び出せます。

判断基準:

- 1 つの stack でしか使わない → `usecase` に直接書く
- 2 つ以上の usecase で同じ構成が出てきた → `module` に切り出す
- 最初から再利用が明確な機能単位 → 最初から `module` にしてよい

## 4. stack の切り方

初期設計では、まず `base` を分けるかどうかを判断し、その後にサービスごとの stack を切ります。

### 4.1 `base`

`base` は、複数サービスから参照される共有基盤を置くための stack です。

例:

- 共通ネットワーク
- 共通 IAM
- 共通 KMS
- 共通 DNS
- 共有ログ基盤

以下に当てはまるなら `base` を独立させる価値があります。

- 複数サービスから参照される
- 変更頻度は低いが影響範囲が広い
- 失敗時の影響が大きい
- サービス側とは別のタイミングで運用したい

### 4.2 サービス stack

共有基盤とは別に、サービスごとに stack を切ります。  
さらに、更新頻度や責務が異なる場合は、1 サービスを複数 stack に分けます。

典型例:

- `<service>-infra`
- `<service>-service`
- `<service>-pipeline`
- `<service>-task`
- `<service>-datastore`

## 5. 典型的な分割パターン

### 5.1 `*-infra`

サービス固有だが、比較的変更頻度が低い基盤リソースを管理します。

例:

- ALB
- Security Group
- ECR
- サービス専用 IAM
- 静的なネットワーク設定

向いているケース:

- アプリのデプロイとは別に更新したい
- 失敗時にランタイム更新へ影響させたくない

### 5.2 `*-service`

アプリケーションの実行面を管理します。

例:

- ECS Service
- Lambda Function
- App Runner Service
- タスク定義

向いているケース:

- アプリリリースに合わせて更新頻度が高い
- ランタイム設定の更新を独立させたい

### 5.3 `*-pipeline`

CI/CD 系のリソースを分離します。

例:

- CodePipeline
- CodeBuild
- デプロイ用 IAM

向いているケース:

- アプリ本体とは異なる担当者が変更する
- デプロイ基盤を独立して更新したい

### 5.4 `*-task`

常駐サービスではないバッチや補助実行系を分けるための stack です。

例:

- ECS one-off task
- バッチ Lambda
- スケジュール実行ジョブ

### 5.5 `*-datastore`

ライフサイクルが重く、破壊的変更の影響が大きいデータ系を分けます。

例:

- RDS
- ElastiCache
- OpenSearch
- 永続 S3

## 6. 一から作るときの設計手順

### 6.1 手順

1. まず、共有基盤を `base` に切り出す必要があるか判断する
2. 次に、サービスごとに「何を独立デプロイしたいか」を洗い出す
3. 変更頻度が異なるものを `infra`、`service`、`pipeline`、`task`、`datastore` などに分ける
4. `terraform/usecases/` に stack ごとの実体を作る
5. `terraform/env/<env>/<stack>/` に root module を作り、対応する usecase を呼び出す
6. 環境差分は `env` 側に集約し、usecase の責務をぶらさない

### 6.2 最小構成の例

小さく始めるなら、まずは次の 3 stack で十分です。

```text
terraform/
  usecases/
    base/
    app-service/
    app-pipeline/
  env/
    dev/
      base/
      app-service/
      app-pipeline/
    stg/
      base/
      app-service/
      app-pipeline/
    prod/
      base/
      app-service/
      app-pipeline/
```

必要になった時点で、`app-service` を `app-infra` と `app-service` に分割したり、`app-datastore` を独立させたりします。

## 7. 分けすぎと分けなさすぎ

### 7.1 分けすぎの兆候

- どの stack を apply すべきか毎回迷う
- 依存関係が多く、順番を覚えないと運用できない
- 1 つの変更で複数 state を毎回同時更新する

### 7.2 分けなさすぎの兆候

- 1 回の `plan` が大きすぎてレビューしづらい
- 低頻度変更と高頻度変更が同居している
- アプリ更新のたびにネットワークや IAM の変更リスクを抱える

## 8. 命名の考え方

- `base`: 共有基盤
- `<service>-infra`: サービス固有の低頻度基盤
- `<service>-service`: ランタイム本体
- `<service>-pipeline`: CI/CD
- `<service>-task`: 補助実行やバッチ
- `<service>-datastore`: データ永続層

名前は、役割が分かることを優先します。  
`core`, `app`, `runtime` などを使ってもよいですが、同じ意味の stack が環境ごとに別名にならないようにします。

## 9. このガイドを他ドキュメントとどう使うか

- 構成全体の設計を考えるときは、このドキュメントを使う
- state 分割の詳細判断は [State 分割ガイド](state-structure.md) を使う
- ファイル構成や書き方は [Terraform コーディング規約](terraform-coding-guideline.md) を使う
- 再利用モジュールの契約設計は [モジュール設計ガイド](module-design-guideline.md) を使う
