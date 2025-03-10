# Dynamicブロックで動的に変数を作成
# セキュリティグループの定義
# var.ingress_rulesに基づいて動的にインバウンドルールを生成します

resource "aws_security_group" "example" {
  # セキュリティグループの基本設定
  name        = "example-sg"
  description = "Example security group"
  vpc_id      = "vpc-12345678"

  # 動的な複数のインバウンドルールの定義
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port   # 開始ポート
      to_port     = ingress.value.to_port     # 終了ポート
      protocol    = ingress.value.protocol    # プロトコル(tcp/udp等)
      cidr_blocks = ingress.value.cidr_blocks # 許可するIPアドレス範囲
    }
  }

  egress {
    from_port   = 0             # すべてのポートを許可
    to_port     = 0             # すべてのポートを許可
    protocol    = "-1"          # すべてのプロトコルを許可
    cidr_blocks = ["0.0.0.0/0"] # すべての送信先を許可
  }
}