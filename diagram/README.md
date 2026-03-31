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
│   └── synthetic-monitoring.yml
├── definitions/             # AWS アイコン定義ファイル
│   └── definition-for-aws-icons-light.yaml
└── synthetic-monitoring.png # 生成された構成図
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
