"""
LLM Batch Sender Lambda Function

SQSメッセージをトリガーとしてLLMバッチリクエストを送信・管理するLambda関数です。

機能:
- SQSメッセージからバッチジョブを処理
- Anthropic Batch APIにリクエストを送信
- バッチ処理ステータスを管理
- 指数バックオフとジッターによるリトライ機能
"""

import json
import logging
import os
import time
from typing import Any, Dict, List
from datetime import datetime, timezone

from anthropic import Anthropic
from anthropic.types import APIError
from botocore.exceptions import ClientError

from common import (
    BatchStateManager,
    BatchStatus,
    ErrorType,
    ProcessingError,
    classify_error,
    get_anthropic_api_key,
    get_dynamodb_table,
    get_required_env,
    get_s3_client,
    handle_error,
    put_s3_object_with_lifecycle,
    success_response,
)

# ログ設定：AWS Lambdaの自動設定を利用
logger = logging.getLogger(__name__)
log_level = os.environ.get("LOG_LEVEL", "INFO").upper()
logger.setLevel(getattr(logging, log_level, logging.INFO))

def handler(event: Dict[str, Any], context) -> Dict[str, Any]:
    """
    SQSトリガー実行用のLambdaハンドラー
    """
    try:
        logger.info(f"バッチ送信イベント処理開始: record_count={len(event.get('Records', []))}, "
                   f"function_name={context.function_name}, aws_request_id={context.aws_request_id}")

        if "Records" not in event:
            raise ValueError("イベントにSQSレコードが見つかりません")

        return handle_sqs_records(event["Records"], context)

    except Exception as e:
        logger.error(f"バッチ送信処理に失敗しました: {str(e)} ({type(e).__name__}), "
                    f"aws_request_id={context.aws_request_id}")
        return handle_error(e, "Failed to process batch sending")


def handle_sqs_records(records: List[Dict[str, Any]], context) -> Dict[str, Any]:
    """
    SQSメッセージを処理します。
    """
    processed_count = 0
    failed_records = []
    processing_results = []

    for record in records:
        try:
            # Lambda残り時間をチェック（最低30秒は残す）
            remaining_time = context.get_remaining_time_in_millis()
            if remaining_time < 30000:  # 30秒未満
                logger.warning(f"Lambda timeout approaching ({remaining_time}ms remaining), terminating processing")
                # 処理中止してSQSに再配信させる
                failed_records.append({
                    "itemIdentifier": record.get("messageId"),
                    "reason": "Lambda timeout approaching"
                })
                continue

            message_body = json.loads(record["body"])
            run_id = message_body.get("run_id")

            if not run_id:
                logger.warning(f"SQSメッセージにrun_idが見つかりません: {record}")
                failed_records.append({
                    "itemIdentifier": record.get("messageId"),
                    "reason": "Missing run_id in message"
                })
                continue

            logger.info(f"バッチリクエスト処理開始: run_id={run_id}")
            
            # バッチリクエストをリトライロジックで処理
            result = process_batch_request_with_retry(run_id, context)
            processing_results.append(result)
            
            if result["success"]:
                processed_count += 1
                logger.info(f"バッチリクエスト処理成功: run_id={run_id}, "
                          f"anthropic_batch_id={result.get('anthropic_batch_id')}")
            else:
                error_reason = result.get("error", "Unknown error")
                should_dlq = result.get("should_dlq", False)
                
                if should_dlq:
                    # DLQに送るため失敗として扱う
                    logger.error(f"バッチリクエスト処理失敗（DLQに送信）: run_id={run_id}, error={error_reason}")
                    failed_records.append({
                        "itemIdentifier": record.get("messageId"),
                        "reason": error_reason
                    })
                else:
                    # 恒久エラーなので成功扱いで削除
                    logger.warning(f"恒久エラーのため成功扱いでDLQ回避: run_id={run_id}, error={error_reason}")
                    processed_count += 1  # 成功としてカウント

        except json.JSONDecodeError as e:
            logger.error(f"SQSメッセージの無効なJSON: {str(e)}")
            failed_records.append({
                "itemIdentifier": record.get("messageId"),
                "reason": f"Invalid JSON: {str(e)}"
            })
        except Exception as e:
            logger.error(f"SQSレコード処理エラー: {str(e)} ({type(e).__name__}), "
                        f"record_id={record.get('messageId')}")
            failed_records.append({
                "itemIdentifier": record.get("messageId"),
                "reason": str(e)
            })

    # SQS partial batch failure response
    response_data = {
        "processed_count": processed_count,
        "total_records": len(records),
        "failed_count": len(failed_records),
        "processing_results": processing_results
    }
    
    if failed_records:
        response_data["batchItemFailures"] = failed_records

    logger.info(f"バッチ処理完了: {response_data}")
    return success_response(response_data)


def process_batch_request_with_retry(run_id: str, context) -> Dict[str, Any]:
    """
    リトライロジック付きでバッチリクエストを処理します。
    """
    max_retries = 5
    base_delay = 1.0  # 1秒
    max_delay = 60.0  # 最大60秒
    
    for attempt in range(max_retries + 1):
        try:
            # Lambda残り時間をチェック
            remaining_time = context.get_remaining_time_in_millis()
            if remaining_time < 15000:  # 15秒未満
                logger.warning(f"リトライ中にLambdaタイムアウト接近 ({remaining_time}ms remaining)")
                return {
                    "success": False,
                    "run_id": run_id,
                    "error": "Lambda timeout approaching",
                    "should_dlq": True,  # 時間切れの場合はDLQに送る
                    "attempt": attempt
                }

            if attempt > 0:
                logger.info(f"リトライ実行 {attempt}/{max_retries} for run_id={run_id}")

            result = process_batch_request(run_id, context)
            
            # 成功した場合はそのまま返す
            if result["success"]:
                if attempt > 0:
                    logger.info(f"{attempt}回のリトライ後に成功: run_id={run_id}")
                return result

            # エラーの場合、リトライすべきかどうか判定
            error_msg = result.get("error", "Unknown error")
            should_retry, should_dlq = should_retry_error(error_msg, attempt, max_retries)
            
            if not should_retry:
                logger.info(f"リトライ対象外エラー: run_id={run_id}: {error_msg}")
                result["should_dlq"] = should_dlq
                return result

            # 最大リトライ回数に達した場合
            if attempt >= max_retries:
                logger.error(f"最大リトライ回数({max_retries})に到達: run_id={run_id}")
                result["should_dlq"] = True
                result["error"] = f"Max retries exceeded: {error_msg}"
                return result

            # バックオフ+ジッターで待機
            delay = calculate_backoff_delay(attempt, base_delay, max_delay)
            logger.info(f"リトライ待機 {delay:.2f}秒 before retry {attempt + 1} for run_id={run_id}")
            time.sleep(delay)

        except Exception as e:
            logger.error(f"リトライループ中の予期しないエラー: {str(e)} ({type(e).__name__}), run_id={run_id}")
            # 予期しないエラーは最終試行でない限りリトライ
            if attempt >= max_retries:
                return {
                    "success": False,
                    "run_id": run_id,
                    "error": f"Unexpected error after {max_retries} retries: {str(e)}",
                    "should_dlq": True,
                    "attempt": attempt
                }
            
            # バックオフ待機
            delay = calculate_backoff_delay(attempt, base_delay, max_delay)
            time.sleep(delay)

    # ここには到達しないはずだが、念のため
    return {
        "success": False,
        "run_id": run_id,
        "error": "Retry logic error",
        "should_dlq": True,
        "attempt": max_retries
    }


def should_retry_error(error_msg: str, attempt: int, max_retries: int) -> tuple[bool, bool]:
    """
    エラーがリトライ対象かどうかを判定します。
    """
    error_lower = error_msg.lower()
    
    # 429 (Rate Limit) - リトライ対象
    if "429" in error_msg or "rate limit" in error_lower or "too many requests" in error_lower:
        return True, True  # リトライし、最終的に失敗したらDLQ
    
    # 5xxエラー - リトライ対象
    if any(code in error_msg for code in ["500", "502", "503", "504"]) or "server error" in error_lower:
        return True, True  # リトライし、最終的に失敗したらDLQ
    
    # ネットワーク関連エラー - リトライ対象
    network_errors = [
        "connection", "timeout", "network", "dns", "ssl", "tls",
        "connection reset", "connection aborted", "connection refused"
    ]
    if any(error in error_lower for error in network_errors):
        return True, True  # リトライし、最終的に失敗したらDLQ
    
    # 4xxエラー（429以外）- 恒久エラー、リトライしない、DLQにも送らない
    if any(code in error_msg for code in ["400", "401", "403", "404", "422"]):
        return False, False  # リトライせず、DLQにも送らない（成功扱い）
    
    # その他のエラー - 念のためリトライ
    return True, True


def calculate_backoff_delay(attempt: int, base_delay: float, max_delay: float) -> float:
    """
    指数バックオフ遅延を計算します
    """
    # 指数バックオフ: base_delay * (2 ^ attempt)
    exponential_delay = base_delay * (2 ** attempt)
    
    # 最大遅延時間で制限
    delay = min(exponential_delay, max_delay)
    
    final_delay = max(0.1, min(delay, max_delay))
    
    return final_delay


def process_batch_request(run_id: str, context) -> Dict[str, Any]:
    """
    バッチリクエストを処理します。
    """
    state_manager = None
    
    try:
        logger.info(f"バッチリクエスト処理開始: run_id={run_id}")
        
        # 状態管理を初期化
        state_manager = BatchStateManager(BatchStatus.QUEUED)
        
        # S3からバッチデータを取得
        batch_data = get_batch_data_from_s3(run_id)
        if not batch_data:
            error = ProcessingError(ErrorType.PERMANENT, "プロンプトが見つかりません")
            state_manager.add_error(error)
            update_batch_status_with_state(run_id, state_manager, context)
            return {"success": False, "run_id": run_id, "error": "Prompt not found"}

        # 処理中に状態遷移
        state_manager.transition_to(
            BatchStatus.PROCESSING, 
            "Anthropicバッチ送信を開始します",
            {"batch_size": batch_data.get("total_requests", 0)}
        )

        # Anthropic Batch APIに送信
        batch_result = send_to_anthropic_batch(batch_data, run_id)
        
        if batch_result["success"]:
            # 成功時の状態更新
            state_manager.transition_to(
                BatchStatus.PROCESSING,  # まだ処理中（Anthropic側で処理される）
                "Anthropicへの送信が完了しました",
                {
                    "anthropic_batch_id": batch_result["batch_id"],
                    "submitted_at": batch_result["submitted_at"]
                }
            )
            
            # Anthropic batch IDでDynamoDBのステータスを更新
            update_result = update_batch_status_with_state(
                run_id, 
                state_manager, 
                context, 
                anthropic_batch_id=batch_result["batch_id"]
            )
            
            return {
                "success": True,
                "run_id": run_id,
                "anthropic_batch_id": batch_result["batch_id"],
                "status_updated": update_result["success"],
            }
        else:
            # 失敗時の処理
            error = ProcessingError(
                ErrorType.RETRIABLE if "rate" in batch_result["error"].lower() else ErrorType.PERMANENT,
                batch_result["error"]
            )
            state_manager.add_error(error)
            
            # リトライ可能かチェック
            if state_manager.should_retry():
                state_manager.transition_to(BatchStatus.RETRYING, "後でリトライします")
            else:
                state_manager.transition_to(BatchStatus.FAILED, "最大リトライ回数を超過しました")
            
            update_batch_status_with_state(run_id, state_manager, context)
            return {"success": False, "run_id": run_id, "error": batch_result["error"]}

    except Exception as e:
        # 予期しないエラーの処理
        logger.error(f"バッチ処理中の予期しないエラー: {str(e)} ({type(e).__name__}), run_id={run_id}")
        
        if state_manager:
            error = classify_error(e)
            state_manager.add_error(error)
            state_manager.transition_to(BatchStatus.FAILED, f"予期しないエラー: {str(e)}")
            update_batch_status_with_state(run_id, state_manager, context)
        
        return {"success": False, "run_id": run_id, "error": str(e)}


def get_batch_data_from_s3(run_id: str) -> dict[str, Any] | None:
    """
    S3からバッチデータを取得します。
    """
    key = f"batches/{run_id}/batch_input.jsonl"

    try:
        s3 = get_s3_client()
        bucket = get_required_env("LLM_PIPELINE_BUCKET")

        try:
            response = s3.get_object(Bucket=bucket, Key=key)
        except s3.exceptions.NoSuchKey:
            # 存在しない場合はNoneを返す
            logger.error(f"バッチデータが見つかりません: {key}")
            return None

        # オブジェクト取得成功
        content = response["Body"].read().decode("utf-8")

        # JSONLをパース
        batch_requests: list[dict[str, Any]] = []
        for line_num, line in enumerate(content.strip().split("\n"), start=1):
            if not line.strip():
                continue
            try:
                batch_requests.append(json.loads(line))
            except json.JSONDecodeError as e:
                logger.warning(f"バッチデータの無効なJSON行 {line_num}: {e}")

        logger.info(f"バッチデータ取得成功: run_id={run_id}, source_key={key}, total_requests={len(batch_requests)}")

        return {
            "requests": batch_requests,
            "source_key": key,
            "total_requests": len(batch_requests),
        }

    except Exception as e:
        logger.error(f"S3からのバッチデータ取得エラー: run_id={run_id}, error={str(e)} ({type(e).__name__})")
        return None


def send_to_anthropic_batch(batch_data: Dict[str, Any], run_id: str) -> Dict[str, Any]:
    """
    Anthropic Batch APIにバッチを送信します。
    """
    try:
        logger.info(f"Anthropic APIにバッチ送信: run_id={run_id}, "
                   f"request_count={len(batch_data['requests'])}")

        # シークレットからAnthropic clientを初期化
        api_key = get_anthropic_api_key()
        client = Anthropic(api_key=api_key)

        # バッチデータをAnthropicにアップロード
        requests_jsonl = "\n".join([
            json.dumps(request, ensure_ascii=False) for request in batch_data["requests"]
        ])
        
        # 入力ファイルを作成
        input_file = client.files.create(
            content=requests_jsonl.encode("utf-8"),
            purpose="batch_prompt",
        )

        logger.debug(f"Anthropic入力ファイル作成完了: file_id={input_file.id}, run_id={run_id}")

        # バッチを作成
        batch = client.beta.messages.batches.create(
            requests_file_id=input_file.id,
        )

        logger.info(f"Anthropicバッチ作成成功: anthropic_batch_id={batch.id}, "
                   f"run_id={run_id}, status={batch.status}")

        # バッチメタデータをS3に保存
        metadata = {
            "run_id": run_id,
            "anthropic_batch_id": batch.id,
            "input_file_id": input_file.id,
            "status": batch.status,
            "created_at": batch.created_at,
            "total_requests": len(batch_data["requests"]),
        }
        
        bucket = get_required_env("LLM_PIPELINE_BUCKET")
        metadata_key = f"batches/{run_id}/metadata.json"
        
        put_s3_object_with_lifecycle(
            bucket=bucket,
            key=metadata_key,
            body=json.dumps(metadata, ensure_ascii=False, default=str),
            retention_days=90
        )

        return {
            "success": True,
            "batch_id": batch.id,
            "input_file_id": input_file.id,
            "status": batch.status,
            "submitted_at": batch.created_at,
            "total_requests": len(batch_data["requests"]),
        }

    except APIError as e:
        # Anthropic APIエラーの詳細処理
        error_msg = f"Anthropic API error ({e.status_code}): {str(e)}"
        logger.error(f"{error_msg}, run_id={run_id}")
        return {"success": False, "error": error_msg}
    
    except Exception as e:
        error_msg = f"Anthropic Batch API送信に失敗しました: {str(e)}"
        logger.error(f"{error_msg} ({type(e).__name__}), run_id={run_id}")
        return {"success": False, "error": error_msg}


def update_batch_status_with_state(
    run_id: str, 
    state_manager: BatchStateManager, 
    context,
    anthropic_batch_id: str = None
) -> Dict[str, Any]:
    """
    状態管理データでバッチステータスを更新します。
    """
    try:
        table = get_dynamodb_table()
        
        # batch_idを使用してレコードを検索（GSIが利用できないためscanを使用）
        response = table.scan(
            FilterExpression="batch_id = :batch_id",
            ExpressionAttributeValues={":batch_id": run_id}
        )
        
        items = response.get("Items", [])
        if not items:
            logger.error(f"バッチレコードが見つかりません: run_id={run_id}")
            return {"success": False, "error": "Batch record not found"}
        
        item = items[0]  # 最初のマッチを取得
        job_id = item["job_id"]
        
        # 状態管理データでupdate準備
        state_data = state_manager.to_dict()
        
        update_expression = """
            SET #status = :status, 
                updated_at = :updated_at,
                state_manager = :state_manager,
                duration_seconds = :duration,
                retry_count = :retry_count
        """
        
        expression_attribute_names = {"#status": "status"}
        expression_attribute_values = {
            ":status": state_manager.current_status.value,
            ":updated_at": datetime.now(timezone.utc).isoformat(),
            ":state_manager": state_data,
            ":duration": state_manager.get_duration(),
            ":retry_count": state_manager.get_retry_count(),
        }
        
        # Anthropic batch IDが提供された場合は保存
        if anthropic_batch_id:
            update_expression += ", anthropic_batch_id = :anthropic_batch_id"
            expression_attribute_values[":anthropic_batch_id"] = anthropic_batch_id
        
        # レコードを更新
        table.update_item(
            Key={"job_id": job_id, "batch_id": run_id},
            UpdateExpression=update_expression,
            ExpressionAttributeNames=expression_attribute_names,
            ExpressionAttributeValues=expression_attribute_values,
        )
        
        logger.info(f"状態管理データでバッチステータス更新完了: run_id={run_id}, job_id={job_id}, "
                   f"status={state_manager.current_status.value}, retry_count={state_manager.get_retry_count()}")
        
        return {"success": True, "job_id": job_id, "batch_id": run_id}
        
    except Exception as e:
        logger.error(f"バッチステータス更新に失敗しました: run_id={run_id}, error={str(e)} ({type(e).__name__})")
        return {"success": False, "error": str(e)} 