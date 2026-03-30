# canary-code/ 変更をトリガーに、zip 化 + S3 アップロード → terraform apply を実行する。

resource "aws_codepipeline" "this" {
  name          = "${local.name_prefix}-synthetics-pipeline"
  pipeline_type = "V2"
  role_arn      = aws_iam_role.pipeline.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.pipeline_artifacts.bucket
  }

  trigger {
    provider_type = "CodeStarSourceConnection"
    git_configuration {
      source_action_name = "Source"
      push {
        branches {
          includes = [var.trigger_branch]
        }
        file_paths {
          includes = var.trigger_paths
        }
      }
    }
  }

  stage {
    name = "Source"
    action {
      name     = "Source"
      category = "Source"
      owner    = "AWS"
      provider = "CodeStarSourceConnection"
      version  = 1
      configuration = {
        FullRepositoryId     = var.github_repository
        BranchName           = var.trigger_branch
        ConnectionArn        = data.aws_codestarconnections_connection.github.arn
        OutputArtifactFormat = "CODE_ZIP"
      }
      output_artifacts = ["SourceOutput"]
    }
  }

  stage {
    name = "Build"
    action {
      name     = "ZipAndUpload"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = 1
      configuration = {
        ProjectName   = aws_codebuild_project.build.name
        PrimarySource = "Source"
      }
      input_artifacts = ["SourceOutput"]
    }
  }

  stage {
    name = "Deploy"
    action {
      name     = "TerraformApply"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = 1
      configuration = {
        ProjectName   = aws_codebuild_project.deploy.name
        PrimarySource = "Source"
      }
      input_artifacts = ["SourceOutput"]
    }
  }
}

# =============================================================================
# Pipeline IAM Role
# =============================================================================

data "aws_iam_policy_document" "pipeline_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "pipeline" {
  name               = "${local.name_prefix}-synthetics-pipeline-role"
  assume_role_policy = data.aws_iam_policy_document.pipeline_assume_role.json
}

data "aws_iam_policy_document" "pipeline" {
  statement {
    effect = "Allow"
    actions = [
      "codestar-connections:UseConnection",
      "codeconnections:UseConnection",
    ]
    resources = [data.aws_codestarconnections_connection.github.arn]
  }

  statement {
    sid    = "S3AccessPolicy"
    effect = "Allow"
    actions = [
      "s3:GetBucketVersioning",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging",
    ]
    resources = [
      "${aws_s3_bucket.pipeline_artifacts.arn}/*",
      aws_s3_bucket.pipeline_artifacts.arn,
    ]
  }

  statement {
    sid    = "CodeBuildAccessPolicy"
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]
    resources = [
      aws_codebuild_project.build.arn,
      aws_codebuild_project.deploy.arn,
    ]
  }
}

resource "aws_iam_role_policy" "pipeline" {
  name   = "${local.name_prefix}-synthetics-pipeline-policy"
  role   = aws_iam_role.pipeline.id
  policy = data.aws_iam_policy_document.pipeline.json
}
