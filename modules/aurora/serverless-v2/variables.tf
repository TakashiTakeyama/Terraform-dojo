variable "cluster_name" {
  description = "Auroraクラスターの名前"
  type        = string
}

variable "engine" {
  description = "データベースエンジン"
  type        = string
  default     = "aurora-postgresql"
}

variable "engine_version" {
  description = "データベースエンジンのバージョン"
  type        = string
  default     = "15.4"
}

variable "instance_class" {
  description = "インスタンスクラス"
  type        = string
  default     = "db.serverless"
}

variable "instances" {
  description = "Auroraインスタンスの設定"
  type = map(object({
    instance_class = string
    identifier     = string
  }))
  default = {
    1 = {
      instance_class = "db.serverless"
      identifier     = "aurora-serverless-1"
    }
  }
}

variable "vpc_id" {
  description = "VPCのID"
  type        = string
}

variable "db_subnet_group_name" {
  description = "DBサブネットグループの名前"
  type        = string
}

variable "subnet_ids" {
  description = "DBサブネットグループに使用するサブネットIDのリスト"
  type        = list(string)
}

variable "create_security_group" {
  description = "セキュリティグループを作成するかどうか"
  type        = bool
  default     = true
}

variable "vpc_security_group_ids" {
  description = "VPCセキュリティグループIDのリスト"
  type        = list(string)
  default     = []
}

variable "security_group_rules" {
  description = "セキュリティグループのルール設定"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}

variable "deletion_protection" {
  description = "削除保護を有効にするかどうか"
  type        = bool
  default     = false
}

variable "enabled_cloudwatch_logs_exports" {
  description = "CloudWatch Logsにエクスポートするログの種類"
  type        = list(string)
  default     = ["postgresql"]
}

variable "manage_master_user_password" {
  description = "マスターユーザーのパスワードを管理するかどうか"
  type        = bool
  default     = true
}

variable "master_username" {
  description = "マスターユーザーのユーザー名"
  type        = string
  default     = "root"
}

variable "database_name" {
  description = "作成するデータベースの名前"
  type        = string
}

variable "serverlessv2_scaling_configuration" {
  description = "Serverless v2のスケーリング設定"
  type = object({
    min_capacity = number
    max_capacity = number
  })
  default = {
    min_capacity = 0.5
    max_capacity = 16
  }
}

variable "preferred_backup_window" {
  description = "バックアップを実行する時間帯"
  type        = string
  default     = "03:00-04:00"
}

variable "preferred_maintenance_window" {
  description = "メンテナンスを実行する時間帯"
  type        = string
  default     = "Mon:04:00-Mon:05:00"
}
