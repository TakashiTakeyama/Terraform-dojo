"""
Lambda関数のHTTPレスポンス処理ユーティリティ

API Gateway Lambda統合で使用される標準的なレスポンス形式を提供し、
エラーハンドリングを統一します。
"""

import json
import os
import traceback
from typing import Any, Dict, List, Optional

from .batch_status import ErrorType, ProcessingError, classify_error


def get_allowed_origins() -> List[str]:
    """
    許可されたオリジンのリストを取得
    
    Returns:
        List[str]: 許可されたオリジンのリスト
    """
    # 環境変数から許可されたオリジンを取得
    allowed_origins_env = os.getenv("ALLOWED_ORIGINS", "")
    
    if allowed_origins_env:
        return [origin.strip() for origin in allowed_origins_env.split(",")]
    
    # デフォルトの許可オリジン（開発・ステージング環境用）
    return [
        "https://localhost:3000",
        "https://staging.hoge.com",
        "https://app.hoge.com"
    ]


def is_origin_allowed(origin: str) -> bool:
    """
    オリジンが許可されているかチェック
    
    Args:
        origin: チェックするオリジン
        
    Returns:
        bool: 許可されている場合True
    """
    allowed_origins = get_allowed_origins()
    
    # 開発環境では全て許可
    if os.getenv("ENVIRONMENT") == "development":
        return True
    
    return origin in allowed_origins


def build_response(
    status_code: int,
    body: Any,
    headers: Optional[Dict[str, str]] = None,
    cors_enabled: bool = True,
    origin: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Lambda proxy response を構築
    
    Args:
        status_code: HTTPステータスコード
        body: レスポンスボディ（JSONシリアライズ可能な値）
        headers: 追加のHTTPヘッダー
        cors_enabled: CORSヘッダーを含めるかどうか
        origin: リクエストのオリジン（CORS用）
        
    Returns:
        Dict[str, Any]: Lambda proxy response形式
    """
    default_headers = {
        "Content-Type": "application/json; charset=utf-8",
        "X-Content-Type-Options": "nosniff",
        "X-Frame-Options": "DENY",
        "X-XSS-Protection": "1; mode=block"
    }
    
    # CORS対応（セキュアな設定）
    if cors_enabled:
        # オリジンが指定されていて許可されている場合のみ設定
        if origin and is_origin_allowed(origin):
            default_headers["Access-Control-Allow-Origin"] = origin
        else:
            # フォールバック（本番環境では制限的に）
            if os.getenv("ENVIRONMENT") == "development":
                default_headers["Access-Control-Allow-Origin"] = "*"
        
        default_headers.update({
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Amz-Date, X-Api-Key, X-Amz-Security-Token",
            "Access-Control-Allow-Credentials": "true"
        })
    
    if headers:
        default_headers.update(headers)
    
    # レスポンスボディの最適化
    if isinstance(body, dict) and not body:
        body_str = "{}"
    else:
        body_str = json.dumps(body, ensure_ascii=False, separators=(",", ":"))
    
    return {
        "statusCode": status_code,
        "body": body_str,
        "headers": default_headers,
    }


def success_response(
    data: Any, 
    headers: Optional[Dict[str, str]] = None,
    origin: Optional[str] = None
) -> Dict[str, Any]:
    """
    成功レスポンス (200 OK)
    
    Args:
        data: レスポンスデータ
        headers: 追加ヘッダー
        origin: リクエストのオリジン
        
    Returns:
        Dict[str, Any]: 成功レスポンス
    """
    return build_response(200, data, headers, cors_enabled=True, origin=origin)


def created_response(
    data: Any, 
    headers: Optional[Dict[str, str]] = None,
    origin: Optional[str] = None
) -> Dict[str, Any]:
    """
    作成成功レスポンス (201 Created)
    
    Args:
        data: 作成されたリソースの情報
        headers: 追加ヘッダー
        origin: リクエストのオリジン
        
    Returns:
        Dict[str, Any]: 作成成功レスポンス
    """
    return build_response(201, data, headers, cors_enabled=True, origin=origin)


def accepted_response(
    data: Any, 
    headers: Optional[Dict[str, str]] = None,
    origin: Optional[str] = None
) -> Dict[str, Any]:
    """
    受付成功レスポンス (202 Accepted)
    
    Args:
        data: 受付情報
        headers: 追加ヘッダー
        origin: リクエストのオリジン
        
    Returns:
        Dict[str, Any]: 受付成功レスポンス
    """
    return build_response(202, data, headers, cors_enabled=True, origin=origin)


def error_response(
    message: str,
    status_code: int = 400,
    error_code: Optional[str] = None,
    error_details: Optional[Dict] = None,
    origin: Optional[str] = None,
) -> Dict[str, Any]:
    """
    エラーレスポンス
    
    Args:
        message: エラーメッセージ
        status_code: HTTPステータスコード
        error_code: アプリケーション固有のエラーコード
        error_details: エラーの詳細情報
        origin: リクエストのオリジン
        
    Returns:
        Dict[str, Any]: エラーレスポンス
    """
    error_body = {
        "error": message,
        "timestamp": "2024-01-01T00:00:00Z"  # 実際の実装では現在時刻を使用
    }
    
    if error_code:
        error_body["error_code"] = error_code
    
    if error_details:
        error_body["details"] = error_details
        
    return build_response(status_code, error_body, cors_enabled=True, origin=origin)


def validation_error_response(
    message: str, 
    field: Optional[str] = None,
    origin: Optional[str] = None
) -> Dict[str, Any]:
    """バリデーションエラーレスポンス (400 Bad Request)"""
    details = {"field": field} if field else None
    return error_response(message, 400, "VALIDATION_ERROR", details, origin)


def not_found_response(
    message: str = "Resource not found",
    resource_type: Optional[str] = None,
    origin: Optional[str] = None
) -> Dict[str, Any]:
    """リソース未発見レスポンス (404 Not Found)"""
    details = {"resource_type": resource_type} if resource_type else None
    return error_response(message, 404, "NOT_FOUND", details, origin)


def internal_error_response(
    message: str = "Internal server error",
    origin: Optional[str] = None
) -> Dict[str, Any]:
    """内部エラーレスポンス (500 Internal Server Error)"""
    return error_response(message, 500, "INTERNAL_ERROR", None, origin)


def rate_limit_response(
    message: str = "Rate limit exceeded",
    retry_after: Optional[int] = None,
    origin: Optional[str] = None
) -> Dict[str, Any]:
    """レート制限エラーレスポンス (429 Too Many Requests)"""
    headers = {}
    if retry_after:
        headers["Retry-After"] = str(retry_after)
    
    details = {"retry_after": retry_after} if retry_after else None
    
    response = error_response(message, 429, "RATE_LIMIT_EXCEEDED", details, origin)
    if headers:
        response["headers"].update(headers)
    
    return response


def handle_error(
    e: Exception,
    default_message: str = "Internal server error",
    log_traceback: bool = True,
    origin: Optional[str] = None,
) -> Dict[str, Any]:
    """
    例外を適切なHTTPレスポンスに変換（改良版）
    
    Args:
        e: 発生した例外
        default_message: デフォルトエラーメッセージ
        log_traceback: トレースバックをログ出力するかどうか
        origin: リクエストのオリジン
        
    Returns:
        Dict[str, Any]: 適切なエラーレスポンス
    """
    # 構造化ログの出力
    error_info = {
        "error_type": type(e).__name__,
        "error_message": str(e),
        "default_message": default_message
    }
    
    if log_traceback:
        error_info["traceback"] = traceback.format_exc()
        print(f"ERROR: {json.dumps(error_info, default=str)}")
    
    # エラーを分類
    processing_error = classify_error(e)
    
    # エラータイプに応じた適切なレスポンスを返す
    if processing_error.error_type == ErrorType.VALIDATION:
        return validation_error_response(str(e), origin=origin)
    elif processing_error.error_type == ErrorType.RATE_LIMIT:
        return rate_limit_response(
            str(e), 
            retry_after=processing_error.retry_after,
            origin=origin
        )
    elif processing_error.error_type == ErrorType.AUTHENTICATION:
        return error_response(str(e), 401, "AUTHENTICATION_ERROR", origin=origin)
    elif processing_error.error_type == ErrorType.RETRIABLE:
        return error_response(str(e), 503, "SERVICE_UNAVAILABLE", 
                            {"retriable": True}, origin=origin)
    elif processing_error.error_type == ErrorType.PERMANENT:
        # 本番環境では詳細なエラーを隠す
        if os.getenv("ENVIRONMENT") == "production":
            return internal_error_response(default_message, origin)
        else:
            return internal_error_response(str(e), origin)
    else:
        # 予期しないエラーは詳細を隠して500を返す
        return internal_error_response(default_message, origin)


def cors_preflight_response(origin: Optional[str] = None) -> Dict[str, Any]:
    """
    CORS preflight request (OPTIONS) への応答
    
    Args:
        origin: リクエストのオリジン
        
    Returns:
        Dict[str, Any]: CORS preflight response
    """
    headers = {
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",  
        "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Amz-Date, X-Api-Key, X-Amz-Security-Token",
        "Access-Control-Max-Age": "86400",  # 24時間
        "Access-Control-Allow-Credentials": "true"
    }
    
    # オリジンが許可されている場合のみ設定
    if origin and is_origin_allowed(origin):
        headers["Access-Control-Allow-Origin"] = origin
    elif os.getenv("ENVIRONMENT") == "development":
        headers["Access-Control-Allow-Origin"] = "*"
    
    return build_response(200, {}, headers, cors_enabled=False) 