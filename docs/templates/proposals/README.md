# 提案書テンプレート

システムの提案・設計・デプロイ計画・セキュリティレビューを行う際に使用するテンプレート集。

## テンプレート一覧

| テンプレート | 用途 | いつ使うか |
|---|---|---|
| [system-proposal.md](./system-proposal.md) | システム提案書 | 新しい仕組み・技術・サービスの導入を提案するとき |
| [technical-design.md](./technical-design.md) | 技術設計書 | 提案が承認された後、詳細な設計・実装方針を詰めるとき |
| [deployment-runbook.md](./deployment-runbook.md) | デプロイ/移行手順書 | 新環境へのデプロイや既存システムの移行を計画するとき |
| [security-review.md](./security-review.md) | セキュリティレビュー | 本番デプロイ前や定期的なセキュリティ評価を行うとき |

## 使い方

1. 目的に合ったテンプレートをコピーする
2. `<!-- ... -->` のコメント部分を参考にしながらセクションを埋める
3. 不要なセクションは削除してよい（全セクション必須ではない）
4. チームレビューに出す

## テンプレートの選び方フロー

```
何かを提案したい
├── まだアイデア段階 → system-proposal.md
├── 提案は承認済み、詳細設計が必要 → technical-design.md
├── 設計は完了、デプロイ/移行の計画が必要 → deployment-runbook.md
└── 本番前のセキュリティ確認が必要 → security-review.md
```

一つのプロジェクトで複数のテンプレートを使うことは一般的。
例: system-proposal → technical-design → security-review → deployment-runbook

## 命名規則

提案書ファイルは以下の形式で命名する。

```
{トピック名}-{テンプレート種別}.md
```

例:
- `synthetic-monitoring-proposal.md`
- `synthetic-monitoring-design.md`
- `prefect-prod-deployment-runbook.md`
- `prefect-security-review.md`
