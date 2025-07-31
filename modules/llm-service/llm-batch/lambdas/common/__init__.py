"""
LLM Batch処理用の共通モジュール

このモジュールは、複数のLambda関数で共有される機能を提供します：
- AWS クライアントの管理
- HTTP レスポンスの構築
- エラーハンドリング
- 環境変数の管理
- 状態管理
"""

from .aws_clients import (
    get_anthropic_api_key,
    get_dynamodb_resource,
    get_dynamodb_table,
    get_required_env,
    get_s3_client,
    get_secret_value,
    get_secrets_client,
    get_sqs_client,
    put_s3_object_with_lifecycle,
)
from .response_utils import (
    accepted_response,
    build_response,
    cors_preflight_response,
    created_response,
    error_response,
    handle_error,
    internal_error_response,
    not_found_response,
    rate_limit_response,
    success_response,
    validation_error_response,
)
from .batch_status import (
    BatchStateManager,
    BatchStatus,
    ErrorType,
    ProcessingError,
    classify_error,
)

__version__ = "0.1.0"

__all__ = [
    # AWS clients
    "get_dynamodb_resource",
    "get_dynamodb_table",
    "get_s3_client",
    "get_sqs_client",
    "get_secrets_client",
    "get_required_env",
    "get_secret_value",
    "get_anthropic_api_key",
    "put_s3_object_with_lifecycle",
    # Response utilities
    "build_response", 
    "success_response",
    "created_response",
    "accepted_response",
    "error_response",
    "validation_error_response",
    "not_found_response",
    "internal_error_response",
    "rate_limit_response",
    "handle_error",
    "cors_preflight_response",
    # State manager
    "BatchStateManager",
    "BatchStatus",
    "ErrorType",
    "ProcessingError",
    "classify_error",
] 