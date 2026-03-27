data "aws_iam_policy_document" "ecs_build" {
  statement {
    sid    = "ECRAuth"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ECRPushPull"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]
    # 本番では対象リポジトリ ARN に絞ること
    resources = [
      "arn:aws:ecr:ap-northeast-1:000000000000:repository/your-repo-name",
    ]
  }
}

data "aws_iam_policy_document" "ecs_deploy" {
  statement {
    sid    = "ECSTaskAndService"
    effect = "Allow"
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:DescribeTaskDefinition",
      "ecs:UpdateService",
      "ecs:DescribeServices",
    ]
    # 本番では対象サービス・タスク定義 ARN に絞ること
    resources = ["*"]
  }

  statement {
    sid    = "PassTaskExecutionRole"
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      "arn:aws:iam::000000000000:role/your-task-execution-role",
    ]
  }
}
