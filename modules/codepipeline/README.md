# codepipeline モジュール群

パイプラインの**型（A / B / C）**ごとに、どの実装を使うかを分けるための索引です。詳細は [CodePipeline（IaC）標準化の方針](../../docs/guidelines/codepipeline-standard-policy.md) の §4 を参照してください。

**呼び出し元**は、環境・スタックごとに state が分かれた **Terraform root**（例: `terraform/env/dev/<stack>/`）を想定する。Dojo 内の具体例は [`terraform/env/dev/`](../../../terraform/env/dev/README.md)。配置の考え方は方針の「利用側リポジトリでの置き場」を参照。

## 型の一覧

| 型 | フロー | 主な用途 | 本リポジトリのモジュール |
|----|--------|----------|---------------------------|
| **A** | Source → Build（1 段） | ビルド・テストのみ | [`github-buildchain`](./github-buildchain/)（`codebuild_stages` が 1 要素） |
| **B** | Source → Build → Build（2 段以上） | ビルド後に AWS へデプロイ | **用途別ラッパー推奨**: Lambda → [`pipeline-app-lambda`](./pipeline-app-lambda/)、ECS → [`pipeline-app-ecs`](./pipeline-app-ecs/)。カスタム段数は [`github-buildchain`](./github-buildchain/) を直接呼ぶ |
| **C** | Source → plan → apply 等（インフラ） | Terraform 等の IaC 実行 | **アプリ用 A/B と別 root / 別 state** で [`pipeline-infra-tf`](./pipeline-infra-tf/) または [`github-buildchain`](./github-buildchain/)（A/B のモジュールと同じファイルに混在させない） |

## なぜ C を分けるか

- IAM（state・ロール・環境）がアプリデプロイと別物になりやすい。
- 失敗時の影響範囲・承認フロー・ブランチ戦略がアプリ CD と一致しないことが多い。
- 型として「インフラ CD」と切り出しておくと、テンプレ選択とレビューが単純になる。

## ディレクトリ

- `github-buildchain/` … **汎用コア**。GitHub ソース + CodeBuild を任意段数で連結（V2）。
- `pipeline-app-lambda/` … 型 B（**Lambda**）向け。`build` → `deploy` 固定。
- `pipeline-app-ecs/` … 型 B（**ECS**）向け。`build`（既定 privileged）→ `deploy` 固定。
- `pipeline-infra-tf/` … 型 C 向け。**`plan` → `apply`** 固定。アプリ用パイプラインと別 root で利用。
