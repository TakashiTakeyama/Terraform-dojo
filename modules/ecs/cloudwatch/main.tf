################################################################################
# Cluster
################################################################################

# ECSクラスター作成
module "ecs_cluster" {
  source = "../../modules/cluster"

  cluster_name = var.name

  # Capacity provider - Fargateとスポットインスタンスの設定
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50 # 通常Fargateの重み
        base   = 20 # 最低限確保するタスク数
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50 # スポットインスタンスの重み
      }
    }
  }
}

################################################################################
# Service
################################################################################

# ECSサービス定義
module "ecs_service" {
  source = "../../modules/service"

  name        = var.name
  cluster_arn = module.ecs_cluster.arn

  cpu    = 1024 # タスク全体のCPUユニット
  memory = 4096 # タスク全体のメモリ（MiB）

  # ECS Execを有効化 - コンテナ内でコマンド実行可能に
  enable_execute_command = true

  # コンテナ定義
  container_definitions = {
    # メインアプリケーションコンテナ
    (var.container_name) = {
      cpu       = 512
      memory    = 1024
      essential = true                                                     # このコンテナが必須
      image     = "public.ecr.aws/aws-containers/ecsdemo-frontend:776fd50" # コンテナイメージ
      port_mappings = [
        {
          name          = var.container_name
          containerPort = var.container_port # コンテナ内部ポート
          hostPort      = var.container_port # ホスト側ポート
          protocol      = "tcp"
        }
      ]

      # ルートファイルシステムへの書き込み許可
      readonly_root_filesystem = false

      # CloudWatchログ設定
      enable_cloudwatch_logging = true
      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_tasks.name
          awslogs-region        = var.region
          awslogs-stream-prefix = var.name
        }
      }

      # Linuxセキュリティパラメータ
      linux_parameters = {
        capabilities = {
          add = [] # 追加する権限なし
          drop = [
            "NET_RAW" # ネットワーク生パケット操作権限を削除
          ]
        }
      }

      memory_reservation = 100 # ソフト制限（MiB）
    }
  }

  # セキュリティグループルール
  security_group_rules = {
    alb_ingress_3000 = {
      type                     = "ingress"
      from_port                = var.container_port
      to_port                  = var.container_port
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = module.alb.security_group_id # ALBからの通信のみ許可
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"          # すべてのプロトコル
      cidr_blocks = ["0.0.0.0/0"] # すべての送信先を許可
    }
  }

  # サービスレベルのタグ
  service_tags = {
    "ServiceTag" = "Tag on service level"
  }
}

################################################################################
# CloudWatch Resources
################################################################################

# CloudWatch ロググループの作成
resource "aws_cloudwatch_log_group" "ecs_tasks" {
  name              = "/ecs/${var.name}"
  retention_in_days = 30
}

# ECSタスク実行ロールの作成
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.name}-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# ECSタスク実行ロールにポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

################################################################################
# CloudWatch Task Definition
################################################################################

# タスク定義
resource "aws_ecs_task_definition" "app" {
  family                   = var.name
  cpu                      = 512
  memory                   = 1024
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = "public.ecr.aws/aws-containers/ecsdemo-frontend:776fd50"
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_tasks.name
          awslogs-region        = var.region
          awslogs-stream-prefix = var.name
        }
      }
    }
  ])
}
