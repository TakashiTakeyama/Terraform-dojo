# Stack Template

各 `terraform/env/<env>/<stack>/` には、最低限以下のファイルを配置する。

- `backend.tf`: backend 設定
- `providers.tf`: provider 設定
- `versions.tf`: Terraform / Provider バージョン
- `main.tf`: モジュール呼び出し
- `variables.tf`: 変数定義
- `outputs.tf`: 必要な出力
