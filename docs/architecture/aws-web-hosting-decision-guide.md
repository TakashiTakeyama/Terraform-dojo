# AWS 上の Web 配信・SSR の考え方

全体の実行基盤（Lambda / ECS / App Runner など）の選び方は [AWS アプリケーション基盤の選定基準](aws-application-platform-decision-guide.md) を先に参照してください。

静的サイトや SPA なら **S3 + CloudFront**。Next.js などで SSR が必要なら **Amplify Hosting** か **ECS/Fargate**。CDN の手前で軽い処理だけなら **CloudFront Functions** か **Lambda@Edge**。大規模で役割分離や自由度が重要なら **CloudFront + 別の実行基盤（ECS/Fargate など）**、という整理がわかりやすいです。

---

## 1. 画面がほぼ完成済みのファイルなら、S3 + CloudFront

React や Vue の SPA をビルドして、最終的に `index.html`、JS、CSS、画像を配るだけなら、サーバー側で毎回計算する必要がありません。S3 に静的ファイルを置き、CloudFront から配信するのが自然です。CloudFront は CDN としてエッジから配信でき、S3 静的サイトは CloudFront と組み合わせて HTTPS や安全な配信構成にしやすいです。

**例**

- LP
- 企業サイト
- 管理画面の SPA
- ビルド済みの Next.js SSG サイト

**ポイント**: ファイル配信で済むので、実行サーバーがいらない。

**このリポジトリとの対応**: `modules/s3/`、`modules/cloudfront/`

---

## 2. リクエストごとに HTML を作るなら、SSR 用の実行基盤が必要

SSR は、アクセスのたびに Node.js などでページを生成して返します。`S3 + CloudFront` だけでは足りず、サーバーコードを実行する場所が別途必要です。Amplify Hosting は SSR アプリをデプロイでき、Node.js ランタイムや CloudWatch Logs にも対応しています。

**例**

- Next.js の SSR
- リクエストごとにユーザー別の内容を描画したい
- SEO のためにサーバー側レンダリングしたい
- A/B テストや地域・権限で表示を変えたい

**ポイント**: ただのファイルではなく、実行が必要。

---

## 3. 小〜中規模で、まず早く作りたいなら Amplify が向く

Amplify は Git 連携でビルド・デプロイを自動化しやすく、ブランチ単位の環境も扱いやすいです。SSR 対応フレームワークのホスティングもできるので、フロント中心の開発では立ち上げが速いです。

**向いている状況**

- フロント主導
- まず早く公開したい
- インフラを細かく作り込みすぎたくない
- Next.js をそのまま載せたい

---

## 4. 大規模で、役割分離や制御が大事なら ECS/Fargate などに分ける

大規模になると、SSR サーバー、API、バッチ、ワーカー、認証、配信経路などを分けて管理したくなることが多いです。ECS/Fargate は ALB と組み合わせて複数タスクへトラフィックを流せますし、HTTP/HTTPS のパスベースルーティングやロードバランシングもできます。

**例**

- SSR サーバーを複数台で運用したい
- API も同じ基盤でまとめて運用したい
- 監視、ログ、スケーリング、デプロイを細かく制御したい
- サービスごとに分離して管理したい

**ポイント**: CloudFront を前段に置き、裏側は ECS/Fargate や別の API 基盤に分ける。

**このリポジトリとの対応**: `modules/ecs/`、`modules/cloudfront/`（オリジンを ALB 等に向ける構成）

---

## 5. 画面全体の SSR は不要だが、少しだけ手を入れたいなら Edge 系

CloudFront Functions と Lambda@Edge は、CloudFront のリクエストやレスポンスに軽い処理を足すためのものです。AWS 公式では、CloudFront Functions は軽量・短時間処理向け、Lambda@Edge はより高度な処理向けとされています。例: リダイレクト、ヘッダ操作、キャッシュキー最適化。

**例**

- URL の正規化
- 国や言語でリダイレクト
- 一部ヘッダの付与
- キャッシュキー調整

**注意**: 本格的な SSR の代わりにはならない。ページ全体をアプリとして動かすなら SSR の実行基盤が必要。

**このリポジトリとの対応**: `modules/cloudfront/` で関数関連リソースを扱う場合あり（プロジェクトのモジュール実装に依存）

---

## ざっくりした判断基準

| 状況 | 候補 |
|------|------|
| HTML / JS / CSS を置いて配るだけ | S3 + CloudFront |
| Next.js で SSR を使う | Amplify Hosting または ECS/Fargate |
| 小規模で早く作りたい | Amplify |
| 大規模で細かく制御したい | CloudFront + ECS/Fargate などに分離 |
| CDN レイヤーで少しだけロジックを足したい | CloudFront Functions / Lambda@Edge |
