# AWS アプリケーション基盤の選定基準

新規プロジェクトや構成変更のときに、**アプリの性質と AWS の実行基盤の対応**を素早く整理するための参照用ドキュメントです。

**スコープ**: 主に**コンピュート（どこでコードを動かすか）**です。RDS、ElastiCache、SQS、認証基盤などは別途設計します。

**関連**: フロント配信・SSR・CDN・Edge に絞った整理は [AWS Web 配信・SSR の考え方](aws-web-hosting-decision-guide.md) を参照してください。

---

## このページの読み方

1. まず **判断軸** で抜けがないか確認する  
2. 迷ったら **決定フロー（分岐）** を上から順にたどる  
3. 表で素早く当てはめるなら **早見表** → **タイプ別** → **形態別（1 枚表）** の順

---

## 判断軸

アプリ基盤を選ぶときは、まず次の 6 つで見ると整理しやすいです。

| 判断軸 | 見ること |
|--------|----------|
| 提供形態 | 静的サイト / Web アプリ / API / バッチ / イベント駆動 |
| 実行時間 | 短時間で終わるか、常時起動が必要か |
| リクエスト特性 | 常時アクセスか、たまにしか来ないか、急増するか |
| 状態管理 | セッション、接続維持、長時間ジョブがあるか |
| 実行環境の自由度 | Docker で十分か、OS まで触りたいか |
| 運用責任 | どこまで自分たちで基盤を持つか |

---

## 決定フロー（分岐）

### 1. 静的ファイルを配るだけか

- **Yes** → **S3 + CloudFront** または **Amplify Hosting**
- **No** → 次へ

事前にビルドした成果物を配るだけなら、常時アプリサーバーを持つ必要はありません。Amplify Hosting は Git ベースのホスティングにも向いています。

### 2. アクセスごとにサーバー処理が必要か

- **Yes** → Web アプリ/API 基盤が必要
- **No** → 静的配信寄り

ログイン、DB 問い合わせ、検索、決済、個別表示などがあるなら、静的サイトだけでは足りません。

### 3. 処理は短時間で終わるか

- **数秒〜短時間、イベントで起動できる** → **Lambda**（HTTP 経由なら **API Gateway** や **Lambda Function URL** と組み合わせることが多い）
- **常時起動が必要、長時間処理あり** → **ECS / App Runner / EC2 / Beanstalk**

Lambda はサーバー不要で自動スケールし、使った分だけ課金されます。常時待ち受けの Web アプリそのものや、接続維持が必要な処理は別基盤のほうが自然です。

### 4. コンテナ前提で標準化したいか

- **Yes** → **ECS/Fargate**（クラスタ運用が既にあるなら **EKS** も比較候補）
- **そこまでではない、もっと簡単に出したい** → **App Runner** か **Elastic Beanstalk**

ECS/Fargate はコンテナ実行の標準基盤として強いです。App Runner はコンテナ化された Web/API を、より少ない基盤意識で出しやすい立ち位置です。Elastic Beanstalk は EC2 ベースの環境構成をまとめて面倒見てくれます。

### 5. OS やミドルウェアまで触りたいか

- **Yes** → **EC2**
- **No** → **ECS / App Runner / Beanstalk / Lambda**

Nginx の細かい調整、独自エージェント、特殊パッケージ、カーネル寄りの話まで行くなら EC2 が候補になります。

---

## 早見表（シチュエーション → 基盤）

| シチュエーション | まず候補 |
|------------------|----------|
| LP・会社サイト・メディアなど、**画面を配るだけ**（静的） | **S3 + CloudFront** / **Amplify Hosting** |
| **Next.js など**の SSR フロント | **Amplify Hosting**（規模・運用要件で **ECS/Fargate** も） |
| **一般的な常時稼働**の業務 Web・アプリ | **ECS/Fargate** |
| コンテナ化した **Web/API を手早く**公開したい | **App Runner** |
| **プラットフォーム任せ**で従来型 Web を比較的そのまま載せたい | **Elastic Beanstalk** |
| Webhook・画像変換・通知など **短時間・イベント駆動** | **Lambda** |
| **長時間ジョブ**・キュー消費ワーカー | **ECS**（要件次第で **AWS Batch** 等） |
| **OS・特殊ミドルウェア**までチューニングしたい | **EC2** |
| 組織として **Kubernetes 運用**が前提 | **EKS**（**ECS/Fargate** と比較） |

---

## タイプ別（アプリの型から）

| アプリのタイプ | まず候補 | 理由 |
|----------------|----------|------|
| HTML/CSS/JS を配るだけのサイト | **S3 + CloudFront / Amplify Hosting** | 事前生成物をそのまま配るのに向く |
| Next.js などのフロント SSR | **Amplify Hosting** | SSR 対応フレームワークを直接ホストしやすい |
| 普通の Web アプリ | **ECS/Fargate** | 常時稼働するアプリを柔軟に運用しやすい |
| Web アプリだが基盤は簡単にしたい | **App Runner** | コンテナ化した Web/API を簡単に公開しやすい |
| API サーバー | **ECS/Fargate / App Runner / Lambda** | 常時稼働型かイベント駆動型かで分かれる |
| バッチ処理 | **ECS / Lambda / Batch** | 長さ・頻度・依存関係で切る |
| イベント駆動の小さな処理 | **Lambda** | サーバー管理不要、使った分課金 |
| 特殊ミドルウェアや OS 調整が必要 | **EC2** | 自由度が最も高い（[Lightsail / Beanstalk / EC2 の比較](https://docs.aws.amazon.com/decision-guides/latest/lightsail-elastic-beanstalk-ec2/lightsail-elastic-beanstalk-ec2.html) なども参照） |

---

## 形態別（静的〜バッチ・1 枚表）

| 形態 | 代表例 | まず候補 |
|------|--------|----------|
| 静的サイト | LP、ドキュメント、SSG | S3 + CloudFront、Amplify |
| SPA | React/Vue ビルド成果物 | S3 + CloudFront、Amplify |
| SSR | Next.js など | Amplify、ECS/Fargate |
| API | REST/GraphQL、gRPC（コンテナ） | ECS、App Runner、Lambda |
| Worker | キュー消費、常時ポーリング | ECS、（用途次第で Lambda） |
| Batch | 定期・長時間ジョブ | ECS、EventBridge + Lambda、Batch 等 |

詳細な CDN・Edge・SSR の切り分けは [AWS Web 配信・SSR の考え方](aws-web-hosting-decision-guide.md) を併せて参照してください。

---

## サービスとざっくり役割

| 用途 | まず候補になるサービス |
|------|------------------------|
| 静的フロント配信 | **Amplify Hosting** / **S3 + CloudFront** |
| Web アプリ・API をコンテナで動かす | **ECS / Fargate**（**EKS** は Kubernetes 前提のとき） |
| Web アプリ・API をもっと簡単に公開したい | **App Runner** |
| 従来型の Web アプリを比較的簡単に載せたい | **Elastic Beanstalk** |
| イベント駆動・短時間処理 | **Lambda** |
| OS やミドルウェアまで強く管理したい | **EC2** |

補足リンク:

- **Amplify Hosting** の SSR: [SSR アプリのデプロイ](https://docs.aws.amazon.com/amplify/latest/userguide/server-side-rendering-amplify.html)、[フレームワークアダプター](https://docs.aws.amazon.com/amplify/latest/userguide/using-framework-adapter.html)
- 全体像: [AWS の概要ホワイトペーパー (PDF)](https://docs.aws.amazon.com/pdfs/whitepapers/latest/aws-overview/aws-overview.pdf)、[App Runner（デプロイオプション概要）](https://docs.aws.amazon.com/whitepapers/latest/overview-deployment-options/aws-apprunner.html)、[Lambda とは](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)

---

## システム構成パターン

### パターン A: 静的フロント + API

- フロント: **Amplify Hosting** か **S3 + CloudFront**
- API: **ECS / App Runner / Lambda**

### パターン B: SSR フロント + API

- フロント: **Amplify Hosting**（または **ECS/Fargate**）
- API: **ECS / Lambda など**

### パターン C: モノリシックな Web アプリ

- **ECS / Beanstalk / EC2**

### パターン D: イベント駆動中心

- **Lambda + 他サービス**（API Gateway、SQS、EventBridge など）

---

## 一言で覚える版

- **Amplify** = フロント寄り
- **Lambda** = 短時間・イベント駆動
- **App Runner** = 簡単な Web/API コンテナ公開
- **ECS** = 本命のアプリ基盤（**EKS** = 同じくコンテナ、K8s 前提）
- **Beanstalk** = 従来型 Web アプリを早く載せる
- **EC2** = 何でもできるが全部持つ
