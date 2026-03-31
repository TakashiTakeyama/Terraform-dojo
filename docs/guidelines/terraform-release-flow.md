# Terraform リリースフローガイド

このドキュメントは、Terraform コードの開発からリリースまでの一連のフローを定義します。  
「コードをどう書くか」はコーディング規約が担い、「書いたコードをどう安全にリリースするか」をこのガイドが担います。

## 1. ブランチ戦略の選択

Terraform リポジトリのブランチ戦略は大きく 2 つあります。プロジェクトの規模やチーム体制に合わせて選択してください。

### 1.1 Develop / Main 方式（推奨）

```text
feature/* ──→ develop ──→ main
               │              │
               ▼              ▼
             Dev apply      Prod apply
```

**特徴:**

- `develop` ブランチで Dev 環境への適用を確認してから `main` へマージ
- Dev と Prod の適用タイミングを明確に分離できる
- 複数メンバーが並行開発しやすい

**向いているケース:**

- Dev と Prod の 2 環境以上がある
- Prod 適用前にレビューと承認を必須にしたい
- チームメンバーが 3 人以上

### 1.2 Trunk-Based 方式

```text
feature/* ──→ main
                │
                ▼
              Dev apply → Prod apply
```

**特徴:**

- `main` ブランチのみ。feature ブランチから直接マージ
- PR マージ → Dev apply → 確認後 Prod apply の直線フロー
- シンプルだが Prod 適用のゲートを CI で確保する必要がある

**向いているケース:**

- 小規模チーム（1〜2 人）
- 環境数が少ない（Dev + Prod のみ）
- 素早いイテレーションを優先したい

### 1.3 選択の判断基準

| 基準 | Develop / Main | Trunk-Based |
|---|---|---|
| チーム規模 | 3 人以上 | 1〜2 人 |
| Prod 適用の慎重さ | 高い（承認フロー必須） | 中程度（CI ゲートで制御） |
| 環境数 | 3 以上（Dev/Stg/Prod） | 2（Dev/Prod） |
| リリース頻度 | 週 1〜数回 | 日次 |

> **注**: 以降のフロー説明は Develop / Main 方式をベースにしています。Trunk-Based の場合は `develop` を `main` に読み替えてください。

## 2. 開発フロー

### 2.1 作業ブランチの作成

```bash
git switch develop
git pull origin develop
git switch -c feature/add-monitoring-stack
```

ブランチ名はチケット番号や変更内容が分かる名前にします。

### 2.2 Terraform コードの実装

[Terraform コーディング規約](terraform-coding-guideline.md) に従って実装します。

変更前に、対象 stack のディレクトリで `plan` を実行し、現在の state との差分がないことを確認してから作業を始めると安全です。

```bash
cd terraform/env/dev/<stack>
terraform init
terraform plan
```

### 2.3 ローカルでの検証（Dev 環境）

Dev 環境に対するローカルからの `terraform apply` は許可します。  
ただし、以下のルールを守ってください。

**許可されること:**

- Dev 環境への `terraform plan` / `terraform apply`
- 検証に必要な一時的なリソースの作成

**禁止されること:**

- Prod 環境へのローカルからの `terraform apply`（緊急時を除く）
- `-target` オプションの使用（依存関係が不整合になるリスクがある）

**注意点:**

- 同じ state を複数人が同時に変更すると state lock の競合が発生します。作業前にチームに共有してください
- 各 stack は独立した state を持つため、作業対象のディレクトリで `init` / `plan` / `apply` を実行してください

### 2.4 プルリクエストの作成

実装と Dev 検証が完了したら、`develop` ブランチに対して PR を作成します。

**PR に含めるべき情報:**

- **変更の概要**: 何を変更したのか、なぜ変更したのか
- **設計判断の理由**: アーキテクチャ選択や trade-off があれば明記
- **plan 結果**: Dev 環境での `terraform plan` 出力（差分がある場合）
- **関連チケット / ドキュメント**: 設計書やイシューへのリンク

### 2.5 CI による自動 Plan

PR を作成すると、CI が自動的に `terraform plan` を実行します。

**CI Plan の推奨構成:**

```text
PR 作成 / 更新
  → terraform fmt -check（フォーマットチェック）
  → terraform validate（構文チェック）
  → terraform plan（差分確認）
  → plan 結果を PR コメントに投稿
```

plan 結果が PR 上で可視化されることで、レビュアーがコード差分だけでなく **実際のインフラ変更** を確認できます。

### 2.6 CI による Apply（Dev 環境）

Dev 環境への適用は、以下のいずれかの方法で行います。

**方式 A: PR コメントトリガー（推奨）**

```text
terraform plan dev <stack>
terraform apply dev <stack>
```

PR のコメント欄にコマンドを書くと CI が実行する方式。操作の意図が PR 上に記録として残るため、監査性が高い。

**方式 B: PR マージトリガー**

`develop` へのマージをトリガーに、自動で Dev 環境に apply する方式。シンプルだが、マージ前に Dev で検証したい場合には不向き。

### 2.7 レビューとマージ

以下の条件を満たしたら PR をマージします。

- レビュアーによる承認を得ている
- Dev 環境に apply 済みで、差分がない（`no-changes`）ことを確認している
- CI チェックが全て通過している

**レビュー省略が許容されるケース:**

- Prod に適用しない一時的なリソース（検証用環境など）
- Dev のみの軽微なプロパティ変更
- ドキュメントのみの変更

> **重要**: Prod のリソースに影響を与える変更は、必ずレビューを通してください。

## 3. リリースフロー（Dev → Prod）

### 3.1 リリース PR の作成

`develop` へのマージ後、`develop → main` の PR を作成します（CI による自動作成を推奨）。

- すでに `develop → main` の PR が存在する場合、追加コミットとして既存の PR に含まれる
- この PR が「次の Prod リリース」の単位になる

### 3.2 自動差分チェック

リリース PR が更新されると、CI が全環境・全 stack の差分チェックを実行します。

```text
PR 更新
  → dev 全 stack: terraform plan
  → prod 全 stack: terraform plan
  → 差分の有無を PR に表示
```

### 3.3 Prod 環境への適用

差分を確認し、Prod に適用します。

```text
terraform plan prod <stack>   # 差分を確認
terraform apply prod <stack>  # 適用
```

**Prod Apply の安全策:**

- **承認ゲート**: CI の apply ジョブに承認ステップを設ける（GitHub Environment の `Required reviewers` など）
- **plan 結果の確認**: apply 前に必ず plan 結果を目視確認する
- **段階適用**: 複数 stack に変更がある場合、依存順に 1 stack ずつ適用する

### 3.4 リリース PR のマージ

全 stack の差分チェックが `no-changes` になったら、リリース PR をマージします。

**マージ条件:**

- 全環境・全 stack で差分なし
- Prod apply 後の差分チェック CI が通過

> マージが遅れると、定期的な差分チェック CI で差分が検知され続けます。apply 後は速やかにマージしてください。

## 4. 安全策とガードレール

### 4.1 `-target` の禁止

CI 経由での `terraform plan` / `terraform apply` で `-target` オプションを使用しないでください。

**理由:**

- 依存関係のあるリソースが適用されず、state が不整合になるリスクがある
- 部分適用は暗黙の前提を作り、次回の `apply` で予期しない変更が発生する

**例外:**

- 大規模なインポートや state 修正で、一時的に `-target` が必要な場合はチームで合意を取る

### 4.2 State Lock と並行作業

Terraform の state lock は「同じ state に対する同時 apply」を防ぎますが、以下に注意してください。

- 同じ stack を複数人が同時に変更する場合、作業前にチームに共有する
- CI と ローカルで同時に apply しない
- lock が残ってしまった場合は `terraform force-unlock` で解除する（原因の特定が先）

### 4.3 Prod Apply の原則

| 項目 | ルール |
|---|---|
| 適用方法 | CI 経由のみ（ローカルからの直接 apply は原則禁止） |
| 承認 | 承認者のレビュー後に apply |
| タイミング | ビジネスインパクトの少ない時間帯を選ぶ |
| 監視 | apply 後に関連するリソースの正常性を確認する |

**Prod のローカル apply が許容されるケース:**

- CI パイプラインが未整備の新規 stack
- 障害などの緊急対応

### 4.4 ロールバック

Terraform に「1 コマンドでロールバック」する機能はありません。以下の方法で対処します。

**方法 1: コードを戻して再 apply**

```bash
git revert <commit>
terraform plan   # 戻ることを確認
terraform apply  # 適用
```

最も安全で確実な方法。新しいリソースの追加を戻す場合に有効。

**方法 2: 前の state を参照して手動修正**

設定値の変更のみの場合、コードを修正して `apply` する方が `revert` より影響範囲が小さいことがある。

**方法 3: `terraform import` で既存リソースを取り込む**

state から消えたリソースを再管理下に置く場合に使う。

> **注意**: `destroy` されたリソースは Terraform だけでは復元できません。Prod apply 前の plan 確認が最も重要な安全策です。

## 5. スムーズなデリバリーのための Tips

### Tip 1: リリース PR を滞留させない

`develop → main` の PR は「Prod に適用する準備ができた変更」を表します。  
apply してマージしない状態が続くと、定期的な差分チェックで差分が検知され続け、ノイズになります。

**対策:** Prod apply が完了したら、その日のうちにマージする。

### Tip 2: 新しい stack を安全に追加する

新しい stack を作成し、Dev で検証してから Prod に展開したい場合:

**Prod の env ディレクトリをまだ作成しない。**

```text
terraform/env/
  dev/
    new-service/   ← Dev で検証中
  prod/
                   ← まだ作らない
```

Dev で十分に検証が完了してから Prod のディレクトリを追加することで、リリース PR に不要な差分が出ません。

### Tip 3: Feature Flag で Dev と Prod の差分を制御する

既存リソースを変更したいが、まだ Prod には適用したくない場合:

```hcl
# usecase の variables.tf
variable "enable_new_monitoring" {
  type        = bool
  description = "新しい監視設定を有効化するかどうか"
}

# usecase のリソース定義
resource "aws_cloudwatch_metric_alarm" "new_alarm" {
  count = var.enable_new_monitoring ? 1 : 0
  # ...
}
```

```hcl
# env/dev/<stack>/main.tf
module "service" {
  source                = "../../../usecases/my-service"
  enable_new_monitoring = true   # Dev で有効
}

# env/prod/<stack>/main.tf
module "service" {
  source                = "../../../usecases/my-service"
  enable_new_monitoring = false  # Prod では無効
}
```

> **禁止**: usecase 内で `var.stage == "dev" ? ...` のような環境名による条件分岐を書かないでください。  
> 環境差分は必ず明示的な変数で env 側から制御します。  
> 詳細は [Terraform コーディング規約](terraform-coding-guideline.md) を参照。

### Tip 4: 大規模変更は段階的にリリースする

多くのリソースに影響する変更（VPC 変更、IAM ポリシー全面改定など）は、1 回の PR で全て変更せず、段階的にリリースします。

```text
PR 1: 新しいリソースを追加（既存に影響なし）
PR 2: 参照先を新しいリソースに切り替え
PR 3: 古いリソースを削除
```

各 PR で Dev → Prod の完全なサイクルを回すことで、問題発生時の影響範囲を限定できます。

### Tip 5: 定期的なドリフト検知

手動変更や外部ツールによる変更で、state とインフラの実態が乖離する（ドリフトする）ことがあります。

**推奨:** 日次や週次で全 stack の `terraform plan` を実行し、想定外の差分がないか確認する。

```text
# CI スケジュール（例: 毎朝 9:00）
全 stack で terraform plan → 差分があれば通知
```

差分が検知された場合の対応:

1. **Terraform コードの変更が原因**: 正常。apply で解消する
2. **手動変更が原因**: 手動変更をコードに反映するか、`apply` で上書きする
3. **外部ツールが原因**: Auto Scaling の `desired_count` 変更など。`lifecycle { ignore_changes }` で対処する

## 6. 緊急対応

### 6.1 緊急フロー

通常フローでは間に合わない障害対応の場合:

1. **hotfix ブランチを作成**: `hotfix/fix-critical-issue`
2. **最小限の変更に留める**: 根本対応は後続の通常 PR で行う
3. **Dev で検証後、速やかに Prod に適用**: レビューは同期的に実施（口頭やチャットで即時確認）
4. **事後対応**: 通常フローに乗せて `develop` / `main` に反映する

### 6.2 Prod へのローカル apply（緊急時のみ）

CI が使えない、または CI の実行を待てない場合に限り、ローカルからの Prod apply を許容します。

**必須事項:**

- 実行前にチームメンバーに連絡する
- `terraform plan` の結果をスクリーンショットやログで記録する
- 実行後にインシデント記録を残す
- 事後に通常フローで `develop` / `main` のコードを同期させる

## 7. よくある質問

### Q: Dev で apply した後、Prod に apply する前に別の変更を develop にマージしてもよい？

**A:** はい。ただし、リリース PR（`develop → main`）に含まれる変更が増えるため、Prod apply 時の plan 結果を注意深く確認してください。変更が大きくなりすぎる場合は、こまめに Prod apply してリリース PR をマージすることを推奨します。

### Q: State lock が残ってしまった場合は？

**A:** まず、lock を取得したプロセスが本当に終了しているか確認してください。CI のジョブが途中で失敗した場合に残ることがあります。確認後、`terraform force-unlock <LOCK_ID>` で解除できます。

### Q: `terraform plan` で差分が出るが、コードは変更していない場合は？

**A:** 以下を確認してください:

1. **Provider のアップデート**: Provider バージョンが変わると、リソースの属性が増減することがある
2. **手動変更**: AWS コンソールや CLI で直接変更された可能性
3. **外部サービスの変更**: Auto Scaling や他サービスによる動的な変更
4. **タイムスタンプ系属性**: 一部リソースは更新日時が毎回変わることがある

### Q: 複数の stack を同時にリリースする順番は？

**A:** 依存関係に従って適用します。一般的な順番:

1. `base`（共有基盤）
2. `*-infra`（サービス固有基盤）
3. `*-datastore`（データ層）
4. `*-service`（ランタイム）
5. `*-pipeline`（CI/CD）

逆に削除する場合は、この逆順で行います。

## 8. フロー全体の図

```text
  Development Flow                    Release Flow
  ========================            ========================
  feature/*                           develop -> main PR
    |                                   |
    v                                   v
  PR (-> develop)                     CI: all-stack diff check
    |                                   |
    +-- CI: fmt / validate / plan       v
    |                                 Prod plan -> review -> apply
    +-- Dev plan -> review -> apply     |
    |                                   v
    v                                 diff check: no-changes?
  Merge to develop                      |
                                        v
                                      Merge to main
```

## 関連ドキュメント

- [Terraform コーディング規約](terraform-coding-guideline.md) — コードの書き方
- [Terraform 構成設計ガイド](terraform-structure-design-guide.md) — ディレクトリ設計と state 分割
- [State 分割ガイド](state-structure.md) — state 分割の詳細な判断基準
- [Terraform レビューチェックリスト](review-checklist.md) — PR レビュー時の確認項目
- [デプロイ方法](../deployment.md) — Terraform の基本操作手順
