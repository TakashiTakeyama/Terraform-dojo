# Stack Template

各 `terraform/env/<env>/<stack>/` には、最低限以下のファイルを配置する。

- `backend.tf`: backend 設定
- `providers.tf`: provider 設定
- `terraform.tf`: Terraform / Provider バージョン
- `main.tf`: モジュール呼び出し
- `variables.tf`: 変数定義
- `locals.tf`: 命名、タグ、共通値の整理
- `outputs.tf`: 必要な出力

`locals.tf` は、現時点で `locals` ブロックがなくても先に作成してよい。  
一方で、用途が曖昧な空ファイルを増やしすぎないこと。

実際のコード例は `root-module-example.md` を参照する。
