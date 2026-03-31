# シェルエイリアス集

Terraform 開発で便利なシェルエイリアスをまとめています。  
`.zshrc` や `.bashrc` にコピーして使ってください。

## Git

```bash
alias ga='git add .'
alias gc='git commit -m'
alias gs='git status'
alias gl='git log'
alias gb='git branch'
alias grs='git reset --soft HEAD^'
alias gsd='git switch develop'
alias gfo='git fetch origin'
alias gpd='git pull origin develop'
alias gupd='git switch develop && git fetch origin && git pull origin develop'
```

## Terraform

```bash
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfv='terraform validate'
alias tff='terraform fmt -recursive'
alias tfo='terraform output'
alias tfs='terraform state list'

# plan + apply を一気に（確認プロンプトあり）
alias tfpa='terraform plan && terraform apply'

# fmt + validate をまとめてチェック
alias tfcheck='terraform fmt -check -recursive && terraform validate'
```

## AWS プロファイル切り替え

```bash
# プロジェクトに合わせて書き換えてください
alias awsdev='export AWS_PROFILE=my-project-dev'
alias awsprod='export AWS_PROFILE=my-project-prod'

# 現在のプロファイルを確認
alias awswho='aws sts get-caller-identity'
```

## 組み合わせ例

```bash
# Dev 環境で init + plan を一発で
alias tfdevp='awsdev && terraform init && terraform plan'

# 現在のディレクトリの stack 名を表示
alias tfwhere='basename $(pwd)'
```
