# Architecture Diagrams

[awsdac (AWS Diagram as Code)](https://github.com/awslabs/diagram-as-code) を使用して、インフラ構成図をコードで管理する。

## セットアップ

### awsdac のインストール

```bash
# macOS (Homebrew)
brew install awsdac

# Go
go install github.com/awslabs/diagram-as-code/cmd/awsdac@latest
```

## ダイアグラムの生成

リポジトリルートで実行する（定義ファイルの相対パス解決のため）。

```bash
# 個別のダイアグラムを生成
awsdac diagram/awsdac/synthetic-monitoring.yml -o diagram/synthetic-monitoring.png

# 全ダイアグラムを一括生成
for f in diagram/awsdac/*.yml; do
  name=$(basename "$f" .yml)
  awsdac "$f" -o "diagram/${name}.png"
done
```

## ディレクトリ構成

```
diagram/
├── README.md
├── awsdac/                  # awsdac ダイアグラム定義 (YAML)
│   ├── synthetic-monitoring.yml
│   ├── multi-account-scheduled-s3-sync.yml
│   └── external-object-storage-datasync-to-s3.yml
├── definitions/             # AWS アイコン定義ファイル
│   └── definition-for-aws-icons-light.yaml
└── *.png                    # 生成された構成図
```

| ディレクトリ | 内容 |
|---|---|
| `awsdac/` | ダイアグラム定義の YAML ファイル。1 ダイアグラム = 1 ファイル。 |
| `definitions/` | awsdac が参照する AWS アイコンの定義ファイル。`tools/make-definition-from-pptx` で自動生成されたもの。 |
| `*.png` | 生成された構成図。コミットに含めておくと PR レビュー等で即確認できる。 |

## ダイアグラムの新規作成手順

### 1. YAML ファイルを作成

`diagram/awsdac/` に YAML を追加する。

```yaml
Diagram:
  DefinitionFiles:
    - Type: LocalFile
      LocalFile: diagram/definitions/definition-for-aws-icons-light.yaml

  Resources:
    Canvas:
      Type: AWS::Diagram::Canvas
      Direction: horizontal
      Children:
        - MyGroup

    MyGroup:
      Type: AWS::Diagram::Resource
      Title: "My Service"
      Preset: "Generic group"
      Children:
        - MyResource

    MyResource:
      Type: AWS::Lambda::Function
      Title: "Lambda Function"
      Preset: "Lambda"

  Links: []
```

### 2. 構成図を生成

```bash
awsdac diagram/awsdac/<name>.yml -o diagram/<name>.png
```

### 3. コミット

YAML と生成された PNG の両方をコミットする。

## よく使う Preset・Type リファレンス

利用可能な Preset と Type は `diagram/definitions/definition-for-aws-icons-light.yaml` に定義されている。
よく使うものを以下にまとめる。

### コンテナ・グループ

| 用途 | Type | Preset |
|---|---|---|
| キャンバス全体 | `AWS::Diagram::Canvas` | - |
| AWS クラウド枠 | `AWS::Diagram::Cloud` | `AWSCloudNoLogo` |
| 汎用グループ | `AWS::Diagram::Resource` | `Generic group` |
| 水平並び | `AWS::Diagram::HorizontalStack` | - |
| 垂直並び | `AWS::Diagram::VerticalStack` | - |

### コンピュート

| 用途 | Type | Preset |
|---|---|---|
| Lambda | `AWS::Lambda::Function` | `Lambda` |
| ECS Fargate | `AWS::Diagram::Resource` | `AWS Fargate` |

### ストレージ

| 用途 | Type | Preset |
|---|---|---|
| S3 | `AWS::S3::Bucket` | `S3 Standard` |

### モニタリング

| 用途 | Type | Preset |
|---|---|---|
| CloudWatch | `AWS::CloudWatch` | `Amazon CloudWatch` |
| Synthetics | `AWS::Synthetics` | `Synthetics` |

### CI/CD

| 用途 | Type | Preset |
|---|---|---|
| CodePipeline | `AWS::Diagram::Resource` | `AWS CodePipeline` |
| CodeBuild | `AWS::Diagram::Resource` | `AWS CodeBuild` |

### その他

| 用途 | Type | Preset |
|---|---|---|
| ユーザー | `AWS::Diagram::Resource` | `Authenticated user` |

### Link の書き方

```yaml
Links:
  - Source: SourceResource
    SourcePosition: E        # N / S / E / W
    Target: TargetResource
    TargetPosition: W
    Type: orthogonal         # orthogonal / direct
    TargetArrowHead:
      Type: Default
    Labels:                  # ラベル（任意）
      TargetRight:
        Title: "label text"
```

## 既存ダイアグラム一覧

| ファイル | 内容 |
|---|---|
| `synthetic-monitoring.yml` | CloudWatch Synthetics 外形監視 + CI/CD パイプライン構成 |
| `multi-account-scheduled-s3-sync.yml` | 複数アカウント間の S3 連携（中間アカウントに EventBridge + Lambda） |
| `external-object-storage-datasync-to-s3.yml` | S3 互換の外部オブジェクトストレージから DataSync で S3 へ取り込み |

## 各ダイアグラムの AWS（関連）サービスと用途

図に出てくる主なコンポーネントが **何のプロダクトで、何のためにあるか** の対応表です。

### `synthetic-monitoring.yml`

| サービス / 要素 | 用途 |
|---|---|
| **Amazon S3** | カナリアスクリプトの zip 配置、実行結果（スクリーンショット・ログ）の保存 |
| **AWS CodePipeline / CodeBuild** | リポジトリのカナリアコードを zip 化し S3 へ配置、カナリア更新までのデプロイ自動化 |
| **Amazon CloudWatch Synthetics** | 定期またはオンデマンドで Web/API の外形監視（シナリオ実行） |
| **Amazon CloudWatch Logs** | カナリア実行ログの保管・調査 |
| **AWS Lambda**（任意） | ログを外部監視 SaaS 等へ転送する場合のフック |
| **AWS Secrets Manager**（任意） | 監視対象への認証情報（Basic 認証トークン等）の安全な参照 |
| **外部監視**（図上は汎用ブロック） | Datadog 等の監視 SaaS へのメトリクス・アラート連携を想定した拡張ポイント |
| **IAM** | カナリア・パイプライン・Lambda が必要な API のみ呼べるよう権限を分離 |

**想定シーン**: 本番 URL や公開 API の死活・レイテンシを継続検知し、デプロイはパイプライン経由で再現性を持たせる。

### `multi-account-scheduled-s3-sync.yml`

| サービス / 要素 | 用途 |
|---|---|
| **Amazon S3** | パートナー／データソース側のオブジェクト置き場、および自社側の集約・加工先バケット |
| **Amazon EventBridge** | 日次・時間単位など **スケジュールで Lambda を起動** するトリガ |
| **AWS Lambda** | バケット間のコピー、メタデータ付与、軽い ETL、通知など **同期ロジックの実装** |
| **IAM** | Lambda 実行ロール、クロスアカウント時はバケットポリシーと組み合わせて最小権限 |

**想定シーン**: 顧客 AWS アカウントのデータを自社アカウントへ定期的に取り込む、複数法人間でハブアカウントを挟んだデータ連携など。

### `external-object-storage-datasync-to-s3.yml`

| サービス / 要素 | 用途 |
|---|---|
| **S3 互換オブジェクトストレージ**（図は汎用ブロック） | 他クラウド・CDN・オンプレ等に置いたオブジェクトの **コピー元**（R2 等の S3 API 互換を想定） |
| **AWS DataSync** | スケジュールまたは手動で **大量・効率的なオブジェクト転送**（検証モードや帯域制御のオプションあり） |
| **Amazon S3** | AWS 上での **正規の保存先**（分析基盤、監査ログ保管、バックアップ先など） |
| **IAM** | DataSync がソース／宛先それぞれのバケットにアクセスするためのロール |

**想定シーン**: エッジや別クラウドに溜まったログ・ファイルを、分析用にリージョン内 S3 へ集約する。

## アーキテクチャ参照（設計メモ）

汎用パターンの「型」として使う想定です。実装では IAM クロスアカウントロール、バケットポリシー、VPC エンドポイント、シークレット管理などを別途設計する。

**サンプル Terraform** は [`terraform/examples/`](../terraform/examples/README.md) を参照（単一アカウントで `plan` / `apply` 検証可能な最小構成）。

### `multi-account-scheduled-s3-sync`

- **要点**: 連携専用の **Hub（Integration）アカウント** に Lambda を置くと、パートナー IAM と自社 IAM を分けやすい。EventBridge のスケジュールは **ルール + ターゲット（Lambda）** で表現する想定。
- **代替案**: 同一アカウント内なら Cloud を 1 つにまとめ、S3 Event Notifications や Step Functions に置き換え可能。

### `external-object-storage-datasync-to-s3`

- **要点**: DataSync はエージェント／ロケーション設定で外部エンドポイントを扱う。図は **論理フロー** のみ。ネットワーク経路（専用線、VPN、パブリック + 制限付き）は別紙で記載する。
- **代替案**: 小規模・低頻度なら Lambda + S3 API コピー、またはベンダー提供のネイティブ連携が選べる。
