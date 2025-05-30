## 1. ワークスペースをTF_WORKSPACEで指定
```
export TF_WORKSPACE=<workspace_name>
例: hoge-xxxx-xxxxの場合
export TF_WORKSPACE="hoge-xxxx-xxxx"
```

## 2. tfvarsファイルを指定してterraformを実行

```
cd terraform
terraform plan -var-file="./tfvars/hoge or fuga/${TF_WORKSPACE}.tfvars"
terraform apply -var-file="./tfvars/hoge or fuga/${TF_WORKSPACE}.tfvars"
```
