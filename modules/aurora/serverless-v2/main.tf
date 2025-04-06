module "cluster" {
  depends_on                           = [aws_db_subnet_group.private]
  version                              = ">=9.13.0"                             # モジュールのバージョン
  source                               = "terraform-aws-modules/rds-aurora/aws" # モジュールのソース
  name                                 = var.cluster_name                       # Auroraクラスターの名前
  engine                               = var.engine                             # データベースエンジン
  engine_version                       = var.engine_version                     # エンジンのバージョン
  instance_class                       = var.instance_class                     # インスタンスクラス
  instances                            = var.instances                          # インスタンスの設定
  vpc_id                               = var.vpc_id                             # VPCのID
  db_subnet_group_name                 = aws_db_subnet_group.private.name       # 作成したDBサブネットグループを使用
  create_security_group                = var.create_security_group              # セキュリティグループを作成するかどうか
  vpc_security_group_ids               = var.vpc_security_group_ids             # 既存のセキュリティグループIDのリスト
  security_group_rules                 = var.security_group_rules               # セキュリティグループのルール
  autoscaling_enabled                  = true                                   # オートスケーリングを有効化
  storage_encrypted                    = true                                   # ストレージの暗号化を有効化
  apply_immediately                    = true                                   # 変更を即時適用
  copy_tags_to_snapshot                = true                                   # スナップショットにタグをコピー
  skip_final_snapshot                  = true                                   # 削除時の最終スナップショットをスキップ
  create_db_subnet_group               = false                                  # DBサブネットグループの作成をスキップ
  deletion_protection                  = var.deletion_protection                # 削除保護の有効/無効
  monitoring_interval                  = 10                                     # モニタリングの間隔（秒）
  enabled_cloudwatch_logs_exports      = var.enabled_cloudwatch_logs_exports    # CloudWatchにエクスポートするログの種類
  manage_master_user_password          = var.manage_master_user_password        # マスターユーザーパスワードの管理
  master_username                      = var.master_username                    # マスターユーザー名
  database_name                        = var.database_name                      # データベース名
  serverlessv2_scaling_configuration   = var.serverlessv2_scaling_configuration # Serverless v2のスケーリング設定
  preferred_backup_window              = var.preferred_backup_window            # バックアップウィンドウ
  preferred_maintenance_window         = var.preferred_maintenance_window       # メンテナンスウィンドウ
  manage_master_user_password_rotation = false                                  # マスターユーザーパスワードのローテーションを無効化
}

resource "aws_db_subnet_group" "private" {
  name       = "${var.db_subnet_group_name}-${var.cluster_name}" # DBサブネットグループの名前
  subnet_ids = var.subnet_ids                                    # サブネットIDのリスト
}
