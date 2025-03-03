# VPCモジュールの定義
# terraform-aws-modules/vpc/awsモジュールを使用してVPCを作成
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.19.0"
  name    = var.vpc.name  # VPC名
  cidr    = "10.0.0.0/16" # VPCのCIDRブロック

  # 利用可能なAZを設定
  azs = local.azs
  # 各AZにパブリックサブネットを作成 (/22 CIDR)
  public_subnets = [for k, v in local.azs : cidrsubnet("10.0.0.0/16", 6, k)]
  # 各AZにプライベートサブネットを作成 (/22 CIDR)
  private_subnets = [for k, v in local.azs : cidrsubnet("10.0.0.0/16", 6, k + 10)]
  # NATゲートウェイを有効化
  enable_nat_gateway = true
  # 単一のNATゲートウェイを使用（コスト最適化）
  single_nat_gateway = true

  # VPC Flow Logs設定 (S3バケットへの出力)
  enable_flow_log                     = true                   # Flow Logsを有効化
  create_flow_log_cloudwatch_iam_role = true                   # IAMロールを自動作成
  flow_log_max_aggregation_interval   = 600                    # ログの集約間隔（秒）
  flow_log_destination_type           = "s3"                   # 出力先タイプ
  flow_log_destination_arn            = var.destination_s3_arn # S3バケットのARN
  flow_log_file_format                = "parquet"              # ログのファイル形式

  # デフォルトリソースのタグ設定
  default_network_acl_tags    = { Name = "${var.vpc.name}-default" }
  default_route_table_tags    = { Name = "${var.vpc.name}-default" }
  default_security_group_tags = { Name = "${var.vpc.name}-default" }

  # サブネットのタグ設定
  public_subnet_tags = {
    "env" = "public"
  }
  private_subnet_tags = {
    "env" = "private"
  }
}

# CloudWatch Logsへの VPC Flow Logs設定
# Flow Logs用のIAMロール作成
resource "aws_iam_role" "local_flow_log_role" {
  name               = "flow-logs-policy-${module.vpc.vpc_id}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Flow Logs用のIAMポリシー作成
resource "aws_iam_role_policy" "logs_permissions" {
  name   = "flow-logs-policy-${module.vpc.vpc_id}"
  role   = aws_iam_role.local_flow_log_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:CreateLogDelivery",
        "logs:DeleteLogDelivery"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:logs:${data.aws_region.current.name}:*:log-group:vpc-flow-logs*"
    }
  ]
}
EOF
}

# CloudWatch Logsのロググループ作成
resource "aws_cloudwatch_log_group" "local_flow_logs" {
  name              = "vpc-flow-logs/${module.vpc.vpc_id}"
  retention_in_days = 30 # ログの保持期間
}

# VPC Flow Logsの設定
resource "aws_flow_log" "local" {
  iam_role_arn    = aws_iam_role.local_flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.local_flow_logs.arn
  traffic_type    = "ALL" # すべてのトラフィックをログ
  vpc_id          = module.vpc.vpc_id
}