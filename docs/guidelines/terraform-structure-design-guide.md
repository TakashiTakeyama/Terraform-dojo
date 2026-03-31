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

## 6. リポジトリ分離戦略

Terraform コードが大きくなると「全部を 1 リポジトリで管理し続けるか、分けるか」という判断が必要になります。  
ディレクトリ分割（state 分割）とリポジトリ分割は別の軸ですが、組み合わせて考えることで運用しやすい構成が作れます。

### 6.1 基本方針

リポジトリ分離の判断は **「誰が」「どの頻度で」変更するか** を軸にします。

- **インフラチーム** が管理する共有基盤・ネットワーク・セキュリティ → **インフラリポジトリ**
- **アプリチーム** が頻繁に変更するサービス定義・タスク定義・CI/CD → **アプリリポジトリ**

### 6.2 分離の判断基準

以下の 2 つ以上に当てはまる場合、リポジトリ分離を検討します。

| 判断基準 | 説明 |
|---|---|
| 変更頻度の差 | インフラ基盤は月 1 回、アプリ関連は週数回など |
| 担当チームの違い | SRE/インフラチームとアプリチームが別れている |
| 承認フローの差 | インフラ変更は厳格なレビュー、アプリ変更は素早くデプロイしたい |
| デプロイサイクルの独立性 | アプリのリリースがインフラ変更にブロックされている |

逆に、チーム規模が小さい（5 人以下など）場合や、インフラとアプリの担当者が同じ場合は、1 リポジトリの方がシンプルです。

### 6.3 典型的な分離パターン

#### パターン A: 単一リポジトリ（小規模〜中規模）

```text
my-project/
  modules/
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
```

チームが小さく、全員がインフラもアプリも触る場合に適しています。  
このリポジトリの `terraform-dojo` 自体がこのパターンです。

#### パターン B: インフラリポジトリ + アプリリポジトリ（中規模〜大規模）

**インフラリポジトリ**（SRE / インフラチームが管理）:

```text
infra-repo/
  modules/
  terraform/
    usecases/
      base/           # VPC, Subnet, NAT, 共通 IAM, 共通 KMS
      security/       # WAF, CloudTrail, GuardDuty
      monitoring/     # CloudWatch, 外部監視連携
      datastore/      # RDS, ElastiCache
    env/
      dev/
        base/
        security/
        monitoring/
        datastore/
      prod/
        ...
```

**アプリリポジトリ**（アプリチームが管理）:

```text
app-repo/
  src/                # アプリケーションコード
  terraform/
    usecases/
      app-service/    # ECS Service, タスク定義, サービス用 IAM
      app-pipeline/   # CodePipeline, CodeBuild
    env/
      dev/
        app-service/
        app-pipeline/
      prod/
        ...
```

#### パターン B の利点

- **アプリチームの自律性**: インフラリポジトリの PR 待ちなしにデプロイ可能
- **変更の追跡が容易**: アプリコードとインフラ定義の変更を同じ PR でレビューできる
- **アクセス制御**: リポジトリ単位で権限を分離できる
- **CI/CD の独立**: アプリリポジトリの push をトリガーにパイプラインを動かせる

#### パターン B の注意点

- インフラリポジトリとアプリリポジトリで **state の依存方向を一方向に保つ**（`infra → app` の逆参照をしない）
- アプリリポジトリからインフラリソース（VPC ID、Subnet ID など）を参照するときは `data` ソースを使う
- `modules/` を共有したい場合は、Git submodule や Terraform Registry ではなく、**各リポジトリに必要な module を持たせる** のが運用上シンプル

### 6.4 何をどちらに置くか

| リソース | インフラリポジトリ | アプリリポジトリ | 判断理由 |
|---|:---:|:---:|---|
| VPC / Subnet | ○ | | 共有基盤、変更頻度低 |
| Security Group | ○ | | ネットワーク設計の一部 |
| RDS / ElastiCache | ○ | | ライフサイクルが長い、破壊的変更のリスク大 |
| WAF / CloudTrail | ○ | | セキュリティ基盤 |
| ECR | ○ | | 複数サービスで共有しうる |
| ALB / Target Group | ○ | | Blue/Green デプロイのため infra 側で安定管理 |
| ECS Service 定義 | | ○ | アプリリリースに連動 |
| Task Definition / IAM | | ○ | アプリの権限要件に密結合 |
| Lambda Function | | ○ | アプリコードと同時に変更 |
| CodePipeline / CodeBuild | △ | △ | パイプライン管理の責任者による（注参照） |
| Secrets Manager（器の作成） | ○ | | インフラ側で一元管理 |

> **注**: CodePipeline をどちらに置くかはチーム構成次第です。  
> インフラチームがパイプラインを管理する場合はインフラリポジトリ、アプリチームが自律的にパイプラインを変更したい場合はアプリリポジトリに置きます。

### 6.5 リポジトリ間の依存解決

リポジトリを分けた場合、リソース間の参照が課題になります。

**推奨: `data` ソースと命名規則で解決する**

```hcl
# アプリリポジトリから VPC を参照
data "aws_vpc" "main" {
  tags = {
    Name = "${var.environment_name}-${var.project_name}-vpc"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  tags = {
    Tier = "private"
  }
}
```

- `terraform_remote_state` はリポジトリ間では**使わない**（state backend の認証情報共有が必要になり、結合度が上がる）
- 命名規則を統一しておけば、`data` ソースで安全に参照できる
- 参照に必要なタグや命名パターンはインフラリポジトリ側で保証する

### 6.6 移行の進め方

既存の単一リポジトリからパターン B に移行する場合の推奨手順:

1. **新規サービスから適用**: 既存リソースは触らず、新しいサービスをアプリリポジトリに作る
2. **既存サービスは段階的に移行**: 大きな変更機会に合わせて `terraform state mv` で移す
3. **共存期間を許容する**: 移行中は両リポジトリにリソースが存在する状態を受け入れる
4. **移行手順を文書化する**: `state mv` の具体的なコマンドと確認手順をチームに共有する

> 関連: アプリリポジトリ側の CI/CD 構成については [ECS アプリケーション CI/CD ガイドライン](app-ecs-cicd-guideline.md) および [Lambda アプリケーション CI/CD ガイドライン](app-lambda-cicd-guideline.md) を参照してください。

## 7. 一から作るときの設計手順

### 7.1 手順

1. まず、Terraform コードを **1 リポジトリで管理するか、分離するか** を判断する（セクション 6 参照）
2. 共有基盤を `base` に切り出す必要があるか判断する
3. サービスごとに「何を独立デプロイしたいか」を洗い出す
4. 変更頻度が異なるものを `infra`、`service`、`pipeline`、`task`、`datastore` などに分ける
5. `terraform/usecases/` に stack ごとの実体を作る
6. `terraform/env/<env>/<stack>/` に root module を作り、対応する usecase を呼び出す
7. 環境差分は `env` 側に集約し、usecase の責務をぶらさない

### 7.2 最小構成の例

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

## 8. 分けすぎと分けなさすぎ

### 8.1 分けすぎの兆候

- どの stack を apply すべきか毎回迷う
- 依存関係が多く、順番を覚えないと運用できない
- 1 つの変更で複数 state を毎回同時更新する

### 8.2 分けなさすぎの兆候

- 1 回の `plan` が大きすぎてレビューしづらい
- 低頻度変更と高頻度変更が同居している
- アプリ更新のたびにネットワークや IAM の変更リスクを抱える

## 9. 命名の考え方

- `base`: 共有基盤
- `<service>-infra`: サービス固有の低頻度基盤
- `<service>-service`: ランタイム本体
- `<service>-pipeline`: CI/CD
- `<service>-task`: 補助実行やバッチ
- `<service>-datastore`: データ永続層

名前は、役割が分かることを優先します。  
`core`, `app`, `runtime` などを使ってもよいですが、同じ意味の stack が環境ごとに別名にならないようにします。

## 10. このガイドを他ドキュメントとどう使うか

- 構成全体の設計を考えるときは、このドキュメントを使う
- state 分割の詳細判断は [State 分割ガイド](state-structure.md) を使う
- ファイル構成や書き方は [Terraform コーディング規約](terraform-coding-guideline.md) を使う
- 再利用モジュールの契約設計は [モジュール設計ガイド](module-design-guideline.md) を使う
- ECS アプリの CI/CD 構成は [ECS アプリケーション CI/CD ガイドライン](app-ecs-cicd-guideline.md) を使う
- Lambda アプリの CI/CD 構成は [Lambda アプリケーション CI/CD ガイドライン](app-lambda-cicd-guideline.md) を使う
