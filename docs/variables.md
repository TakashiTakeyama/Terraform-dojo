# 変数一覧

このプロジェクトで使用する変数の一覧です。各モジュールで使用される変数の詳細説明を提供しています。

## 共通変数

| 変数名     | 説明                 | タイプ | デフォルト値     |
| ---------- | -------------------- | ------ | ---------------- |
| `region`   | デフォルトリージョン | string | `ap-northeast-1` |
| `vpc_name` | メイン VPC の名前    | string | -                |

## SSM EC2 変数

| 変数名            | 説明                                       | タイプ | デフォルト値 |
| ----------------- | ------------------------------------------ | ------ | ------------ |
| `workspaces_name` | Terraform Cloud のワークスペース名         | string | -            |
| `ami_name`        | AMI の名前                                 | string | -            |
| `ssm_ec2`         | SSM EC2 の設定（instance_type, subnet_id） | object | -            |
| `user_data`       | ユーザーデータ                             | string | -            |

## KMS 変数

| 変数名               | 説明                                                       | タイプ       | デフォルト値 |
| -------------------- | ---------------------------------------------------------- | ------------ | ------------ |
| `key_administrators` | KMS キーの管理者権限を付与する IAM ユーザーの ARN のリスト | list(string) | -            |
| `aliases`            | KMS キーに付与するエイリアス名のリスト                     | list(string) | -            |

## IAM 変数

| 変数名                    | 説明                                   | タイプ       | デフォルト値 |
| ------------------------- | -------------------------------------- | ------------ | ------------ |
| `iam_user_name`           | IAM ユーザーの名前                     | string       | -            |
| `create_access_key`       | アクセスキーを作成するかどうか         | bool         | `true`       |
| `create_login_profile`    | ログインプロファイルを作成するかどうか | bool         | `true`       |
| `password_reset_required` | パスワードリセットが必要かどうか       | bool         | `true`       |
| `force_destroy`           | ユーザーを強制的に削除するかどうか     | bool         | `true`       |
| `iam_policy_arns`         | IAM ポリシーの ARN のリスト            | list(string) | -            |

## S3 変数

| 変数名                  | 説明                                     | タイプ | デフォルト値 |
| ----------------------- | ---------------------------------------- | ------ | ------------ |
| `s3_bucket_name`        | S3 バケットの名前                        | string | -            |
| `s3_acl`                | バケットのアクセスコントロールリスト     | string | `private`    |
| `s3_force_destroy`      | バケットを強制的に削除するかどうか       | bool   | `false`      |
| `s3_versioning_enabled` | バージョニングを有効にするかどうか       | bool   | `false`      |
| `s3_sse_enabled`        | サーバーサイド暗号化を有効にするかどうか | bool   | `true`       |
| `s3_kms_key_id`         | 暗号化に使用する KMS キーの ID           | string | `null`       |
| `s3_lifecycle_rules`    | ライフサイクルルールの設定               | any    | `[]`         |

## ECR 変数

| 変数名                     | 説明                                     | タイプ       | デフォルト値 |
| -------------------------- | ---------------------------------------- | ------------ | ------------ |
| `dev_repos`                | 開発環境の ECR リポジトリ設定            | map(object)  | `{}`         |
| `ga_role_names`            | GitHub Actions 用の IAM ロール名のリスト | list(string) | `[]`         |
| `github_oidc_provider_arn` | GitHub OIDC プロバイダーの ARN           | string       | -            |

## Lambda 変数

| 変数名          | 説明                      | タイプ | デフォルト値 |
| --------------- | ------------------------- | ------ | ------------ |
| `function_name` | Lambda 関数の名前         | string | -            |
| `description`   | Lambda 関数の説明         | string | -            |
| `image_uri`     | Lambda 関数のイメージ URI | string | -            |

## その他の変数

その他のモジュールで使用される変数については、各モジュールのドキュメントを参照してください。
