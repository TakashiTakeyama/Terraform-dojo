################################################################################
# ECS Cluster
################################################################################

# ECSクラスターを作成
resource "aws_ecs_cluster" "c" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = var.container_insights ? "enabled" : "disabled"
  }
}

# クラスター用のCloudWatchロググループ
resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/ecs/${var.cluster_name}"
  retention_in_days = var.log_retention_days
}

################################################################################
# ECS Service
################################################################################

resource "aws_ecs_service" "services" {
  depends_on = [aws_ecs_cluster.c]
  for_each   = local.merged_services

  # サービス名
  name = each.key
  # クラスター設定
  cluster = aws_ecs_cluster.c.arn

  # デプロイ設定
  deployment_maximum_percent         = each.value.deployment_maximum_percent
  deployment_minimum_healthy_percent = each.value.deployment_minimum_healthy_percent
  desired_count                      = each.value.desired_count

  # 起動タイプ設定
  launch_type      = each.value.launch_type
  platform_version = each.value.platform_version

  # タスク定義設定
  task_definition = each.value.task_definition

  # その他の設定
  #   availability_zone_rebalancing     = each.value.availability_zone_rebalancing
  enable_ecs_managed_tags           = each.value.enable_ecs_managed_tags
  enable_execute_command            = each.value.enable_execute_command
  force_delete                      = each.value.force_delete
  force_new_deployment              = each.value.force_new_deployment
  health_check_grace_period_seconds = each.value.health_check_grace_period_seconds
  iam_role                          = each.value.iam_role
  propagate_tags                    = each.value.propagate_tags
  scheduling_strategy               = each.value.scheduling_strategy
  triggers                          = each.value.triggers
  wait_for_steady_state             = each.value.wait_for_steady_state

  # デプロイサーキットブレーカー設定 - enableがtrueの場合のみブロックを作成
  dynamic "deployment_circuit_breaker" {
    for_each = each.value.deployment_circuit_breaker_enable ? [1] : []
    content {
      enable   = true
      rollback = each.value.deployment_circuit_breaker_rollback
    }
  }

  # デプロイコントローラー設定
  deployment_controller {
    type = each.value.deployment_controller_type
  }

  # ネットワーク設定
  network_configuration {
    assign_public_ip = each.value.assign_public_ip
    security_groups  = each.value.security_groups
    subnets          = each.value.subnets
  }
}
