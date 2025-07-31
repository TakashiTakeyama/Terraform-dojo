# 現在のAWSリージョン情報を取得
data "aws_region" "current" {}

# 指定したVPC名でVPC情報を取得
data "aws_vpc" "main_vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# VPC内の「private」を含む名前のサブネットID一覧を取得
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main_vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

# 各privateサブネットIDごとにサブネット情報を取得
data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

# 利用可能なアベイラビリティゾーン情報を取得（オプトイン不要なもののみ）
data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Lambda実行用IAMロールの信頼ポリシードキュメント
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Anthropic API Key
data "aws_secretsmanager_secret_version" "anthropic_api_key" {
  secret_id = "development/hoge-voice-llm-pipeline/anthropic_api_key"
}

# LLM Pipeline API Key
data "aws_ssm_parameter" "llm_pipeline_api_key" {
  name            = "/dev/hoge-voice/step_functions/llm_pipeline_api_key"
  with_decryption = true
}