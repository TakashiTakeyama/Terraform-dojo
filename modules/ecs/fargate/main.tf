################################################################################
# Cluster
################################################################################

module "ecs_cluster" {
  source = "../../modules/cluster"

  cluster_name = local.name

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

module "ecs_service" {
  source = "../../modules/service"

  name        = local.name
  cluster_arn = module.ecs_cluster.arn

  cpu    = 1024 # タスク全体のCPUユニット
  memory = 4096 # タスク全体のメモリ（MiB）

  # ECS Execを有効化 - コンテナ内でコマンド実行可能に
  enable_execute_command = true

  # コンテナ定義
  container_definitions = {

    # Fluentbitコンテナ - ログ収集用
    fluent-bit = {
      cpu       = 512
      memory    = 1024
      essential = true                                                 # このコンテナが必須
      image     = nonsensitive(data.aws_ssm_parameter.fluentbit.value) # SSMパラメータストアから最新イメージを取得
      firelens_configuration = {
        type = "fluentbit" # FireLensタイプの指定
      }
      memory_reservation = 50  # ソフト制限（MiB）
      user               = "0" # rootユーザーで実行
    }

    # メインアプリケーションコンテナ
    (local.container_name) = {
      cpu       = 512
      memory    = 1024
      essential = true                                                     # このコンテナが必須
      image     = "public.ecr.aws/aws-containers/ecsdemo-frontend:776fd50" # コンテナイメージ
      port_mappings = [
        {
          name          = local.container_name
          containerPort = local.container_port # コンテナ内部ポート
          hostPort      = local.container_port # ホスト側ポート
          protocol      = "tcp"
        }
      ]

      # ルートファイルシステムへの書き込み許可
      readonly_root_filesystem = false

      # コンテナの依存関係
      dependencies = [{
        containerName = "fluent-bit" # 依存するコンテナ名
        condition     = "START"      # 起動条件
      }]

      # CloudWatchログ無効化（FireLensを使用するため）
      enable_cloudwatch_logging = false
      # FireLensログ設定
      log_configuration = {
        logDriver = "awsfirelens"
        options = {
          Name                    = "firehose" # Firehoseへ送信
          region                  = local.region
          delivery_stream         = "my-stream"
          log-driver-buffer-limit = "2097152" # バッファサイズ
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

      # ボリューム共有設定（例示用）
      volumes_from = [{
        sourceContainer = "fluent-bit"
        readOnly        = false
      }]

      memory_reservation = 100 # ソフト制限（MiB）
    }
  }

  # Service Connect設定 - サービスディスカバリ
  service_connect_configuration = {
    namespace = aws_service_discovery_http_namespace.this.arn
    service = {
      client_alias = {
        port     = local.container_port
        dns_name = local.container_name # サービス名
      }
      port_name      = local.container_name
      discovery_name = local.container_name
    }
  }

  # ロードバランサー設定
  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["ex_ecs"].arn
      container_name   = local.container_name
      container_port   = local.container_port
    }
  }

  # ネットワーク設定
  subnet_ids = module.vpc.private_subnets # プライベートサブネットに配置
  # セキュリティグループルール
  security_group_rules = {
    alb_ingress_3000 = {
      type                     = "ingress"
      from_port                = local.container_port
      to_port                  = local.container_port
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
# Standalone Task Definition (w/o Service)
################################################################################

module "ecs_task_definition" {
  source = "../../modules/service"

  # サービス設定
  name        = "${local.name}-standalone"
  cluster_arn = module.ecs_cluster.arn

  # タスク定義
  volume = {
    ex-vol = {} # 空のボリューム定義
  }

  # ランタイムプラットフォーム設定
  runtime_platform = {
    cpu_architecture        = "ARM64" # ARMアーキテクチャ
    operating_system_family = "LINUX"
  }

  # コンテナ定義
  container_definitions = {
    al2023 = {
      image = "public.ecr.aws/amazonlinux/amazonlinux:2023-minimal" # Amazon Linux 2023

      # ボリュームマウント設定
      mount_points = [
        {
          sourceVolume  = "ex-vol",
          containerPath = "/var/www/ex-vol" # コンテナ内マウントパス
        }
      ]

      # 実行コマンド
      command    = ["echo hello world"]
      entrypoint = ["/usr/bin/sh", "-c"]
    }
  }

  # ネットワーク設定
  subnet_ids = module.vpc.private_subnets

  # セキュリティグループルール
  security_group_rules = {
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"          # すべてのプロトコル
      cidr_blocks = ["0.0.0.0/0"] # すべての送信先を許可
    }
  }

  tags = local.tags
}

################################################################################
# Supporting Resources
################################################################################

# FluentBitイメージのSSMパラメータ取得
data "aws_ssm_parameter" "fluentbit" {
  name = "/aws/service/aws-for-fluent-bit/stable"
}

# サービスディスカバリ名前空間
resource "aws_service_discovery_http_namespace" "this" {
  name        = local.name
  description = "CloudMap namespace for ${local.name}"
}

# ALB（Application Load Balancer）設定
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name = local.name

  load_balancer_type = "application"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets # パブリックサブネットに配置

  # 本番環境では有効化すべき
  enable_deletion_protection = false

  # セキュリティグループ - インバウンドルール
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0" # インターネットからのHTTPアクセスを許可
    }
  }
  # セキュリティグループ - アウトバウンドルール
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"                      # すべてのプロトコル
      cidr_ipv4   = module.vpc.vpc_cidr_block # VPC内部への通信のみ許可
    }
  }

  # リスナー設定
  listeners = {
    ex_http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "ex_ecs" # 転送先ターゲットグループ
      }
    }
  }

  # ターゲットグループ設定
  target_groups = {
    ex_ecs = {
      backend_protocol                  = "HTTP"
      backend_port                      = local.container_port
      target_type                       = "ip" # IPアドレスベースのターゲット
      deregistration_delay              = 5    # 登録解除遅延（秒）
      load_balancing_cross_zone_enabled = true # クロスゾーンロードバランシング有効化

      # ヘルスチェック設定
      health_check = {
        enabled             = true
        healthy_threshold   = 5     # 正常判定しきい値
        interval            = 30    # チェック間隔（秒）
        matcher             = "200" # 成功レスポンスコード
        path                = "/"   # チェックパス
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5 # タイムアウト（秒）
        unhealthy_threshold = 2 # 異常判定しきい値
      }

      # ECSサービスがタスクIPを自動アタッチするため手動アタッチは不要
      create_attachment = false
    }
  }
}
