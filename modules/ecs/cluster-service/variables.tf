variable "cluster_name" {
  description = "クラスター名"
  type        = string
}

variable "container_insights" {
  description = "Container Insightsの有効化"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatchログの保持期間（日）"
  type        = number
}

variable "default_service_settings" {
  description = "Serviceのデフォルト値"
  type = object({
    deployment_maximum_percent         = number
    deployment_minimum_healthy_percent = number
    desired_count                      = number
    launch_type                        = string
    platform_version                   = string
    # availability_zone_rebalancing       = bool
    enable_ecs_managed_tags             = bool
    enable_execute_command              = bool
    force_delete                        = bool
    force_new_deployment                = bool
    health_check_grace_period_seconds   = number
    iam_role                            = string
    propagate_tags                      = string
    scheduling_strategy                 = string
    triggers                            = map(string)
    wait_for_steady_state               = bool
    deployment_circuit_breaker_enable   = bool
    deployment_circuit_breaker_rollback = bool
    deployment_controller_type          = string
    assign_public_ip                    = bool
    security_groups                     = list(string)
    subnets                             = list(string)
  })
  default = {
    deployment_maximum_percent         = 200
    deployment_minimum_healthy_percent = 100
    desired_count                      = 1
    launch_type                        = "FARGATE"
    platform_version                   = "LATEST"
    # availability_zone_rebalancing       = false
    enable_ecs_managed_tags             = true
    enable_execute_command              = false
    force_delete                        = false
    force_new_deployment                = false
    health_check_grace_period_seconds   = 0
    iam_role                            = null
    propagate_tags                      = "SERVICE"
    scheduling_strategy                 = "REPLICA"
    triggers                            = {}
    wait_for_steady_state               = false
    deployment_circuit_breaker_enable   = false
    deployment_circuit_breaker_rollback = false
    deployment_controller_type          = "ECS"
    assign_public_ip                    = false
    security_groups                     = []
    subnets                             = []
  }
}

variable "services" {
  description = "Serviceの設定"
  type = map(object({
    task_definition                    = string           # タスク定義ARNまたは名前:リビジョン
    deployment_maximum_percent         = optional(number) # デプロイ中の最大タスク数（パーセント）
    deployment_minimum_healthy_percent = optional(number) # デプロイ中の最小ヘルシータスク数（パーセント）
    desired_count                      = optional(number) # 実行するタスク数
    launch_type                        = optional(string) # 起動タイプ（FARGATE/EC2）
    platform_version                   = optional(string) # プラットフォームバージョン
    # availability_zone_rebalancing       = optional(bool)         # AZリバランシングの有効化
    enable_ecs_managed_tags             = optional(bool)         # ECSマネージドタグの有効化
    enable_execute_command              = optional(bool)         # ECS Execの有効化
    force_delete                        = optional(bool)         # 強制削除の有効化
    force_new_deployment                = optional(bool)         # 新規デプロイメントの強制
    health_check_grace_period_seconds   = optional(number)       # ヘルスチェック猶予期間（秒）
    iam_role                            = optional(string)       # IAMロール
    propagate_tags                      = optional(string)       # タグの伝播設定
    scheduling_strategy                 = optional(string)       # スケジューリング戦略
    triggers                            = optional(map(string))  # トリガー設定
    wait_for_steady_state               = optional(bool)         # 安定状態待機の有効化
    deployment_circuit_breaker_enable   = optional(bool)         # デプロイサーキットブレーカーの有効化
    deployment_circuit_breaker_rollback = optional(bool)         # デプロイ失敗時のロールバック有効化
    deployment_controller_type          = optional(string)       # デプロイコントローラータイプ
    assign_public_ip                    = optional(bool)         # パブリックIPの割り当て
    security_groups                     = optional(list(string)) # セキュリティグループID
    subnets                             = optional(list(string)) # サブネットID
  }))
}
