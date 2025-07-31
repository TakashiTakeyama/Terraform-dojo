"""
AWS クライアントの管理モジュール

Lambda関数間で共通して使用されるAWSクライアントの初期化と管理を行います。
シングルトンパターンを使用してメモリ効率を向上させます。
"""

import json
import os
from typing import Optional

import boto3
from boto3.dynamodb.conditions import Attr, Key
from botocore.config import Config
from botocore.exceptions import ClientError

# AWS クライアント最適化用の設定
_aws_config = Config(
    retries={'max_attempts': 3, 'mode': 'adaptive'},
    max_pool_connections=50,
    region_name=os.getenv('AWS_REGION', 'ap-northeast-1')
)

# グローバル変数でクライアントを管理（Lambda環境での再利用）
_dynamodb_resource: Optional[boto3.resource] = None
_sqs_client: Optional[boto3.client] = None  
_s3_client: Optional[boto3.client] = None
_secrets_client: Optional[boto3.client] = None

# キャッシュされたシークレット
_cached_secrets: dict = {}


def get_dynamodb_resource() -> boto3.resource:
    """
    DynamoDB resourceを取得（再利用）
    
    Returns:
        boto3.resource: DynamoDB resource
    """
    global _dynamodb_resource
    if _dynamodb_resource is None:
        _dynamodb_resource = boto3.resource("dynamodb", config=_aws_config)
    return _dynamodb_resource


def get_dynamodb_table(table_name: Optional[str] = None):
    """
    DynamoDBテーブルを取得
    
    Args:
        table_name: テーブル名。Noneの場合は環境変数から取得
        
    Returns:
        DynamoDBテーブルオブジェクト
        
    Raises:
        RuntimeError: テーブル名が指定されず環境変数も未設定の場合
    """
    if table_name is None:
        table_name = get_required_env("DYNAMODB_TABLE_NAME")
    
    dynamodb = get_dynamodb_resource()
    return dynamodb.Table(table_name)


def get_sqs_client() -> boto3.client:
    """
    SQS clientを取得（再利用）
    
    Returns:
        boto3.client: SQS client
    """
    global _sqs_client
    if _sqs_client is None:
        _sqs_client = boto3.client("sqs", config=_aws_config)
    return _sqs_client


def get_s3_client() -> boto3.client:
    """
    S3 clientを取得（再利用）
    
    Returns:
        boto3.client: S3 client
    """
    global _s3_client
    if _s3_client is None:
        _s3_client = boto3.client("s3", config=_aws_config)
    return _s3_client


def get_secrets_client() -> boto3.client:
    """
    Secrets Manager clientを取得（再利用）
    
    Returns:
        boto3.client: Secrets Manager client
    """
    global _secrets_client
    if _secrets_client is None:
        _secrets_client = boto3.client("secretsmanager", config=_aws_config)
    return _secrets_client


def get_secret_value(secret_name: str, force_refresh: bool = False) -> dict:
    """
    AWS Secrets Manager からシークレットを取得
    
    Args:
        secret_name: シークレット名
        force_refresh: キャッシュを無視して強制更新するか
        
    Returns:
        dict: シークレットの値
        
    Raises:
        RuntimeError: シークレットの取得に失敗した場合
    """
    global _cached_secrets
    
    # キャッシュから取得（強制更新でない場合）
    if not force_refresh and secret_name in _cached_secrets:
        return _cached_secrets[secret_name]
    
    try:
        secrets_client = get_secrets_client()
        response = secrets_client.get_secret_value(SecretId=secret_name)
        
        # JSON形式のシークレットをパース
        secret_value = json.loads(response['SecretString'])
        
        # キャッシュに保存
        _cached_secrets[secret_name] = secret_value
        
        return secret_value
        
    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'ResourceNotFoundException':
            raise RuntimeError(f"Secret '{secret_name}' not found")
        elif error_code == 'InvalidRequestException':
            raise RuntimeError(f"Invalid request for secret '{secret_name}'")
        elif error_code == 'InvalidParameterException':
            raise RuntimeError(f"Invalid parameter for secret '{secret_name}'")
        else:
            raise RuntimeError(f"Failed to retrieve secret '{secret_name}': {str(e)}")
    except json.JSONDecodeError:
        raise RuntimeError(f"Secret '{secret_name}' is not valid JSON")
    except Exception as e:
        raise RuntimeError(f"Unexpected error retrieving secret '{secret_name}': {str(e)}")


def get_anthropic_api_key() -> str:
    """
    Anthropic API キーを Secrets Manager から取得
    
    Returns:
        str: API キー
        
    Raises:
        RuntimeError: API キーの取得に失敗した場合
    """
    secret_name = get_optional_env("ANTHROPIC_SECRET_NAME", "anthropic-api-key")
    secret_data = get_secret_value(secret_name)
    
    if "api_key" not in secret_data:
        raise RuntimeError(f"Secret '{secret_name}' does not contain 'api_key' field")
    
    return secret_data["api_key"]


def get_required_env(key: str) -> str:
    """
    必須環境変数を安全に取得
    
    Args:
        key: 環境変数名
        
    Returns:
        str: 環境変数の値
        
    Raises:
        RuntimeError: 環境変数が未設定の場合
    """
    value = os.getenv(key)
    if not value:
        raise RuntimeError(f"Environment variable '{key}' must be set")
    return value


def get_optional_env(key: str, default: str = "") -> str:
    """
    オプション環境変数を取得
    
    Args:
        key: 環境変数名
        default: デフォルト値
        
    Returns:
        str: 環境変数の値またはデフォルト値
    """
    return os.getenv(key, default)


def put_s3_object_with_lifecycle(
    bucket: str, 
    key: str, 
    body: str, 
    retention_days: int = 30,
    content_type: str = "application/json"
) -> None:
    """
    S3にオブジェクトを保存（ライフサイクル管理付き）
    
    Args:
        bucket: S3バケット名
        key: オブジェクトキー
        body: オブジェクトの内容
        retention_days: 保持期間（日数）
        content_type: コンテンツタイプ
    """
    s3 = get_s3_client()
    
    # 保持期間に応じてストレージクラスを選択
    storage_class = 'STANDARD_IA' if retention_days > 30 else 'STANDARD'
    
    s3.put_object(
        Bucket=bucket,
        Key=key,
        Body=body,
        ContentType=content_type,
        StorageClass=storage_class,
        Tagging=f'retention={retention_days}&created_by=llm-batch-service'
    )


# よく使用される条件式をエクスポート
__all__ = [
    # AWS Clients
    "get_dynamodb_resource",
    "get_dynamodb_table", 
    "get_sqs_client",
    "get_s3_client",
    "get_secrets_client",
    # Environment variables
    "get_required_env",
    "get_optional_env",
    # Secrets Manager
    "get_secret_value",
    "get_anthropic_api_key",
    # S3 utilities
    "put_s3_object_with_lifecycle",
    # DynamoDB conditions
    "Key",
    "Attr",
] 