# dev/base sample stack

`dev` 環境の基盤スタック例です。  
このサンプルは、スタック構成を学ぶために `terraform_data` リソースのみを作成します。

## ファイル構成

- `backend.tf`: backend 設定テンプレート
- `terraform.tf`: Terraform / Provider バージョン
- `providers.tf`: AWS provider と default tags
- `variables.tf`: スタック入力
- `main.tf`: サンプルリソース
- `outputs.tf`: 出力
