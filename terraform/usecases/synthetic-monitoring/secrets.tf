# Secrets Manager は器のみ作成する。実際の値は手動または別プロセスで設定する。
resource "aws_secretsmanager_secret" "web_signin" {
  name = "${var.environment_name}/${var.project_name}/web_canary_signin"
}
