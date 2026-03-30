# Terraform コーディング規約

このドキュメントは、`Terraform-dojo` で Terraform コードを追加・修正する際の基本ルールを定義します。  
主な目的は、モジュール利用者が迷わず使えること、`terraform plan` の差分が予測しやすいこと、長期運用で破綻しにくいことです。

詳細なモジュール設計は `module-design-guideline.md`、state 分割は `state-structure.md`、レビュー観点は `review-checklist.md` を参照してください。

## 1. 基本原則

- 明示性を優先し、実際に作成されるリソースや設定値をコードから追いやすくする
- 抽象化は必要最小限に留め、読みやすさと保守性を優先する
- 変更の安全性を重視し、`plan` 差分の予測可能性を高く保つ
- 一時的に便利でも、将来の利用者やレビュアーが理解しにくい構成は避ける

## 2. 適用範囲

本リポジトリの Terraform コードは、次の 3 つの役割に分かれます。

- `root module`（`terraform/env/<env>/<stack>/`）: state を持ち、環境固有値を渡す。backend / provider / version を管理する
- `usecase`（`terraform/usecases/<stack>/`）: stack の実体。環境に依存しないリソース定義を置く。1 つの root module から呼ばれる
- `reusable module`（`modules/<module-name>/`）: 複数の usecase から再利用される汎用部品

基本的な呼び出しの流れは `env -> usecases -> modules` です。

### `usecase` と `module` の違い

- `usecase` は「ある stack で何を作るか」を定義する。特定のサービスや責務に紐づく
- `module` は「どう作るか」を部品化したもの。特定のサービスに依存しない

たとえば:

- `usecases/core-service/`: このサービスの ECS、ALB、Security Group などをまとめて定義する
- `modules/ecs-service/`: ECS Service + Task Definition + Auto Scaling を汎用的にまとめた部品。`core-service` からも `public-api` からも呼べる

判断基準:

- 1 つの stack でしか使わない → `usecase` に直接書く
- 2 つ以上の usecase で同じ構成が出てきた → `module` に切り出す
- 最初から再利用が明確な機能単位 → 最初から `module` にしてよい

### 2.1 標準ディレクトリ構成

Terraform コードは、役割ごとに以下のディレクトリに配置します。

```text
terraform-dojo/
  modules/                 # 再利用可能モジュール
  terraform/
    usecases/              # stack の実体
    env/
      <env>/
        <stack>/           # root module
```

- `modules/`: 複数の stack やプロジェクトから呼び出す再利用可能モジュールを置く
- `terraform/usecases/`: stack ごとの実体を置く
- `terraform/env/<env>/<stack>/`: state を持つ root module を置く
- 新しい構成を追加するときは、既存の責務境界を崩さない

### 2.2 標準ファイル構成

`root module`、`usecase`、`reusable module` では、基本となるファイルセットを揃えます。  
将来の差分を見通しやすくするため、まだ中身がなくても先に作成してよいファイルがあります。

#### `root module`

`terraform/env/<env>/<stack>/` では、原則として以下を配置します。

- `backend.tf`: backend 設定
- `providers.tf`: provider 設定
- `terraform.tf`: Terraform / Provider バージョン制約
- `main.tf`: モジュール呼び出しや主要定義
- `variables.tf`: root module の入力
- `locals.tf`: 命名、タグ、共通値の整理
- `outputs.tf`: 他ツールや利用者に渡す出力
- `README.md`: stack の目的と運用メモ。必要に応じて追加する

#### `usecase`

`terraform/usecases/<stack>/` では、原則として以下を配置します。

- `main.tf`: 主要なリソース定義や module 呼び出し
- `variables.tf`: env から受け取る入力
- `locals.tf`: 共通値や入力正規化
- `outputs.tf`: env や他ツールに返す出力
- `terraform.tf`: Terraform / Provider バージョン制約
- 機能別ファイル（`ecs.tf`、`alb.tf`、`iam.tf` など）: リソースが増えたら機能単位で分割する

#### `reusable module`

`modules/<module-name>/` では、原則として以下を配置します。

- `main.tf`: モジュールの主要定義
- `variables.tf`: 入力定義
- `locals.tf`: 共通値や入力正規化
- `outputs.tf`: 出力定義
- `terraform.tf`: Terraform / Provider バージョン制約
- `README.md`: 利用方法、入力、出力、注意点

#### ファイルの扱い

- `locals.tf` は、まだ `locals` を使っていなくても先に作成してよい
- 将来的に使うことが明らかな基本ファイルは、初期状態で揃えておくことを推奨する
- 一方で、用途が曖昧な空ファイルを増やしすぎない
- `data.tf`、`iam.tf`、`network.tf` などの機能別ファイルは、必要になった時点で追加する

## 3. リソース定義

### 3.1 `for_each` / `count`

- `count` は主に「作成する / しない」の 0 or 1 制御に使う
- `for_each` は、入力と生成結果の対応関係が読み取りやすい場合に限定して使う
- 単一リソースしか作らないのに、将来の拡張を見越して抽象化するのは避ける
- 動的生成によってレビュー時に実体が追いにくくなる場合は、明示的な定義を優先する

```hcl
# ✅ count を 0 or 1 制御に使う
resource "aws_route53_record" "optional_record" {
  count = var.enable_dns_record ? 1 : 0

  zone_id = data.aws_route53_zone.main.zone_id
  name    = "api.example.com"
  type    = "A"
}
```

### 3.2 `locals`

- 重複削減、共通タグ、入力値の正規化など、意味のある共通化に使う
- 単純な文字列補間を隠すだけの `locals` は作らない
- 大きな設定オブジェクトを `locals` に押し込んで、実際のリソース定義を見えにくくしない
- **許容されるケース**: ECS タスク定義など、JSON 構造を整理する目的での使用

```hcl
# ✅ 推奨: 直接インラインで記述
resource "aws_ecs_cluster" "this" {
  name = "${var.stage}-${var.project}-cluster"
}

# ❌ 非推奨: 単純な補間を locals に入れる
locals {
  name_prefix = "${var.stage}-${var.project}"
}

resource "aws_ecs_cluster" "this" {
  name = "${local.name_prefix}-cluster"
}
```

### 3.3 `data` ソース

- 既存リソースを安全に参照できるなら、`data` ソースを活用する
- 呼び出し側で容易に導出できる値まで、過剰に input として受け取らない
- ただし、`data` ソースを増やしすぎて暗黙依存が増える場合は、明示的な入力の方が適切なこともある
- **env から渡さずに、usecases 内で直接取得する**: 変数名を組み合わせて data を取得できるリソースは、usecases 内の `data.tf` で直接取得する

```hcl
# ✅ 推奨: usecases の data.tf で直接取得
data "aws_vpc" "main" {
  tags = {
    Name = "${var.stage}-${var.project}-vpc"
  }
}

data "aws_subnet" "private1" {
  vpc_id = data.aws_vpc.main.id

  tags = {
    Name = "${var.stage}-${var.project}-private-subnet-1"
  }
}

# ❌ 非推奨: env で取得して variable で渡す
# env/main.tf
# data "aws_vpc" "main" { ... }
# module "example_service" {
#   vpc_id = data.aws_vpc.main.id  # これは不要
# }
```

### 3.4 リソースとポリシーの分離による循環参照の回避

IAM Policy や Security Group は、リソースとポリシーを別で作成することにより循環参照を防ぎます。

- `aws_vpc_security_group_ingress_rule` / `aws_vpc_security_group_egress_rule` を使用する
- `aws_iam_role_policy_attachment` や `aws_iam_policy` を分離する
- ファイルを機能単位で分割しても、相互参照が可能になる

```hcl
# ecs.tf
resource "aws_security_group" "ecs" {
  name   = "${var.stage}-${var.project}-ecs-sg"
  vpc_id = var.vpc_id
}

# alb.tf
resource "aws_security_group" "alb" {
  name   = "${var.stage}-${var.project}-alb-sg"
  vpc_id = var.vpc_id
}

# ALB → ECS の通信許可（循環参照なし）
resource "aws_vpc_security_group_ingress_rule" "alb_to_ecs" {
  security_group_id            = aws_security_group.ecs.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}
```

## 4. 入力値の設計

### 4.1 `variable`

- すべての入力変数に `type` と `description` を定義する
- 不正値を早期に防げる場合は `validation` を付ける
- 環境で実際に変わる値だけを入力にする
- 真偽値には `enable_`, `create_`, `is_`, `has_` などの接頭辞を付ける

### 4.2 `tfvars`

- `tfvars` は必要な場合のみ明示的に使う
- `.auto.tfvars` の常用は避け、意図しない自動読込を防ぐ
- 機密値を `tfvars` にコミットしない
- 環境差分をディレクトリ構成で表現できるなら、その方法を優先する
- `.auto.tfvars` を使用しない場合、**root module（env）にはそもそも variable を記述しない**方針を推奨する。環境固有の値は、モジュール呼び出し時に直接記述する

```hcl
# ✅ 推奨: root module（env）でモジュール呼び出し時に直接値を渡す
module "network" {
  source = "../../../usecases/base"

  stage   = "dev"
  project = "my-project"
  vpc_cidr_block = "10.0.0.0/16"
}

# usecase 側では variable を定義してよい
# terraform/usecases/base/variables.tf
# variable "stage" {
#   type        = string
#   description = "環境名（dev, stg, prod）"
# }
```

### 4.3 `output`

- 呼び出し側が本当に必要な値だけを公開する
- 名前は用途が明確に分かるものにする
- 内部実装の都合だけで `output` を増やさない

## 5. ファイル分割

- ファイルは機能単位で分割する
- 単に AWS リソース種別ごとに分けるより、変更理由と責務が追いやすい構成を優先する
- 関連する IAM、Security Group、監視設定などは、必要に応じて同じ機能単位にまとめてよい
- 巨大な単一ファイルと過剰な細分化の両方を避ける

## 6. 命名規則

### 6.1 Terraform リソース識別子

- `snake_case` を使用する
- 意味のある、説明的な名前を付ける
- そのモジュールで 1 つしか存在せず限定する必要がない場合は `this` にする
- 略語は一般的なものに限り、意味が伝わる名前を優先する
- AWS のサービス名をリソースの識別子に含めない

```hcl
# ✅ 良い例
resource "aws_security_group" "api_server" { }
resource "aws_iam_role" "ecs_task_execution" { }

# ❌ 悪い例
resource "aws_security_group" "sg1" { }
resource "aws_iam_role" "target_role" { }
```

### 6.2 変数名

- `snake_case` を使用する
- ブール値には `enable_`, `create_`, `is_`, `has_` などの接頭辞を付ける
- 環境名の変数名はプロジェクト内で統一する（例: `stage` または `environment_name`）

### 6.3 AWS リソース名

**`${stage}-${project}-descriptor` パターンに従う**

AWS 上で表示されるリソース名（`Name` タグ、リソースの `name` 属性）は、環境・プロジェクト・役割が識別できるパターンで命名します。

```hcl
# ✅ 推奨: パターンに従った命名
resource "aws_security_group" "alb" {
  name = "${var.stage}-${var.project}-alb-sg"
  # → "dev-my-project-alb-sg"
}

resource "aws_lb_target_group" "api" {
  name = "${var.stage}-myprj-api-tg"
  # → "dev-myprj-api-tg"（32 文字制限のため略称を使用）
}

# ❌ 非推奨: 環境名やプロジェクト名がない
resource "aws_security_group" "alb" {
  name = "alb-security-group"
  # どの環境のリソースか不明
}
```

- 文字数制限があるリソース（Target Group は 32 文字など）では、プロジェクト名を略称にする
- descriptor 部分はリソースの役割を示す具体的な名前にする
- リポジトリ全体で命名規則を統一し、同種のリソースで揺れを作らない

## 7. セキュリティ

### 7.1 機密情報の管理

- 機密情報を Terraform コードや平文ファイルに直接書かない
- シークレットはマネージドな secret store を利用する。AWS では `Secrets Manager` を推奨する
- Terraform では器（`aws_secretsmanager_secret`）のみ作成し、値は手動投入する
- 詳細は [シークレット情報の管理規約](secrets-management-guideline.md) を参照する

### 7.2 IAM ポリシー

- 最小権限を原則とし、`*` の利用は必要最小限にする
- JSON 記述には `aws_iam_policy_document` を使う（IDE での型推論が効き、可読性が向上する）
- JSON 文字列でのインライン記述は避ける

```hcl
# ✅ 推奨: aws_iam_policy_document を使用
data "aws_iam_policy_document" "s3_read_only" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.data.arn,
      "${aws_s3_bucket.data.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "s3_read_only" {
  name   = "${var.stage}-${var.project}-s3-read-only"
  policy = data.aws_iam_policy_document.s3_read_only.json
}

# ❌ 非推奨: JSON 文字列でインライン記述
resource "aws_iam_policy" "s3_read_only" {
  name = "${var.stage}-${var.project}-s3-read-only"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:ListBucket"]
      Resource = ["*"]
    }]
  })
}
```

### 7.3 Security Group の最小権限

- DB、キャッシュ、アプリケーション用の Security Group では、`0.0.0.0/0` への全開放は原則禁止
- 通信先が特定できる場合は、対象の Security Group や CIDR ブロック・ポートを明示する
- `0.0.0.0/0` が必要な場合（外部 API 呼び出しなど）は、その理由をコメントで明記する

```hcl
# ✅ 推奨: 必要な宛先に制限した egress
resource "aws_vpc_security_group_egress_rule" "to_database" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.database.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "to_redis" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.redis.id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
}

# ❌ 非推奨: 全宛先への全開放
resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
```

## 8. バージョン管理

### 8.1 Terraform バージョンの固定

- 各 root module で `.terraform-version` ファイルを使用してバージョンを固定する
- tenv 等のバージョン管理ツールで自動的にバージョンを切り替えられるようにする

### 8.2 `root module`

- Terraform / Provider バージョンは完全に固定する
- バージョンが上がると plan 結果が変わる可能性があり危険

```hcl
# root module: 完全固定
terraform {
  required_version = "1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.80.0"
    }
  }
}
```

### 8.3 `reusable module`

- 再利用可能モジュールは `>=` で下限指定を基本とする
- 「このバージョン以上を保証する」という意味で使う
- バージョン制約の変更が利用者に与える影響を考慮する

```hcl
# reusable module: 下限指定
terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.80.0"
    }
  }
}
```

## 9. 依存関係と state 参照

- State は用途や環境で分割し、責務を明確にする
- 詳細な分割方針は `state-structure.md` を参照する
- `terraform_remote_state` は state 間の密結合を生みやすいため原則として避ける
- 使う場合は、依存する `output`、更新手順、破壊的変更時の扱いを文書化する
- 既存リソース参照は、可能なら `data` ソースや命名規則で解決する

## 10. 外部モジュールの扱い

- 外部モジュールは、内容を理解できる場合に限って採用する
- 採用時は、ブラックボックス化、追従コスト、`plan` 予測性を確認する
- バージョンは明示的に制約し、理由を README や PR に残す
- 自前で実装した方が分かりやすく保守しやすい場合は、無理に導入しない

**例外として許容するモジュール:**

- `terraform-aws-modules/vpc/aws`: 長年の運用実績があり、VPC のような複雑な基盤リソースで有益

```hcl
# ✅ 許容: VPC モジュール（バージョン固定必須）
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${var.stage}-${var.project}-vpc"
  cidr = "10.0.0.0/16"
}

# ❌ 非推奨: その他の外部モジュール
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.0.0"
}
```

## 11. ECS パターン

### 11.1 Auto Scaling と `desired_count` の管理

Auto Scaling を使用するサービスでは `desired_count` の変更を Terraform で無視します。

- `desired_count` の初期値は Terraform で設定するが、Auto Scaling が動的に変更するため `lifecycle` で無視する
- `terraform apply` 時に Auto Scaling が調整した値がリセットされることを防ぐ

```hcl
# ✅ 推奨: Auto Scaling 使用時
resource "aws_ecs_service" "this" {
  name            = "${var.stage}-${var.project}-api"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 2

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# ❌ 非推奨: Auto Scaling 使用時に lifecycle がない
# → apply のたびに desired_count がリセットされる
```

### 11.2 ヘルスチェックの設定

Target Group の `health_check.matcher` には、アプリケーションが返す具体的なステータスコードを指定します。

- `"200-399"` のような広い範囲は、リダイレクト等の想定外のレスポンスもヘルシーとみなしてしまう
- 正常時に返すコードが明確な場合は、そのコードのみを指定する

```hcl
# ✅ 推奨: 具体的なステータスコード
resource "aws_lb_target_group" "api" {
  name     = "${var.stage}-myprj-api-tg"
  port     = 8080
  protocol = "HTTP"

  health_check {
    path    = "/health"
    matcher = "200"
  }
}

# ❌ 非推奨: 広すぎるステータスコード範囲
resource "aws_lb_target_group" "api" {
  health_check {
    path    = "/health"
    matcher = "200-399"
  }
}
```

## 12. 例外ルール

- 規約から外れる実装が必要な場合は、理由が説明できることを前提とする
- 将来の利用者やレビュアーが判断に迷う箇所には、短いコメントや README を追加する
- 「一度だけ使うから」「とりあえず動くから」は例外理由として弱い

## 13. レビュー前チェック

変更内容に応じて、最低限以下を実施すること:

```bash
terraform fmt -recursive
terraform validate
terraform plan
```

必要に応じて `tflint`、`tfsec`、`checkov` なども実施する。
