"""
LLM Batch Collector Lambda Function

EventBridgeで定期実行されるLambda関数で、バッチ処理の状態収集を行います。

機能:
- EventBridgeによる定期実行でDynamoDBから対象をQuery
- Anthropic Batch APIのステータスを取得
- completedなら結果をS3へ保存（JSONL）し、DynamoDBを更新
- in_progressなどは状態維持しつつlast_checked_atを更新
- 直接Invoke（{"run_id": "..."}）でも単発チェック可能
"""

import json
import logging
import os
from typing import Any, Dict, List, Optional
from datetime import datetime, timezone

from boto3.dynamodb.conditions import Key, Attr
from anthropic import Anthropic

from common import (
    BatchStateManager,
    BatchStatus,
    ErrorType,
    ProcessingError,
    classify_error,
    get_anthropic_api_key,
    get_dynamodb_table,
    get_required_env,
    handle_error,
    put_s3_object_with_lifecycle,
    success_response,
)

# ログ設定：AWS Lambdaの自動設定を利用
logger = logging.getLogger(__name__)
log_level = os.environ.get("LOG_LEVEL", "INFO").upper()
logger.setLevel(getattr(logging, log_level, logging.INFO))

# DynamoDB GSI名（Terraformで作成しておくこと）
DDB_STATUS_INDEX_NAME = os.environ.get("DDB_STATUS_INDEX_NAME", "status-index")       # PK: status, SK: updated_at(推奨)
DDB_BATCH_ID_INDEX_NAME = os.environ.get("DDB_BATCH_ID_INDEX_NAME", "batch_id-index") # PK: batch_id

# 1回の起動で処理する最大件数（queued/processingを均等割り）
MAX_CHECKS_PER_INVOCATION = int(os.environ.get("MAX_CHECKS_PER_INVOCATION", "200"))

# 安全域（ミリ秒）：Lambdaタイムアウト直前でループを抜ける
SAFETY_MILLIS = int(os.environ.get("SAFETY_MILLIS", "5000"))

def _now_iso() -> str:
    """現在時刻をISO8601形式で取得"""
    return datetime.now(timezone.utc).isoformat()

def _to_dict_safe(obj: Any) -> Any:
    """Anthropic SDKなどのモデルを安全に辞書化"""
    try:
        if hasattr(obj, "model_dump"):
            return obj.model_dump()
        if hasattr(obj, "to_dict"):
            return obj.to_dict()
        # __dict__は内部属性を含むことがあるため最後の手段
        return json.loads(json.dumps(obj, default=str))
    except Exception:
        return str(obj)

def handler(event: Dict[str, Any], context) -> Dict[str, Any]:
    """
    Lambda handler for EventBridge or direct invocation
    """
    try:
        logger.info(f"バッチ収集開始: source={event.get('source', 'direct')}, "
                   f"function_name={context.function_name}, aws_request_id={context.aws_request_id}")

        if event.get("source") == "aws.events":
            return handle_scheduled_polling(event, context)

        # 直接実行（手動/単発チェック用）
        return handle_direct_invocation(event, context)

    except Exception as e:
        logger.error(f"バッチ収集処理に失敗しました: {str(e)} ({type(e).__name__}), "
                    f"aws_request_id={context.aws_request_id}")
        return handle_error(e, "Failed to process batch collection")


def handle_scheduled_polling(event: Dict[str, Any], context) -> Dict[str, Any]:
    """
    EventBridgeからの定期起動で、queued/processingをQueryしてチェック
    """
    try:
        table = get_dynamodb_table()
        per_status_limit = max(1, MAX_CHECKS_PER_INVOCATION // 2)
        statuses = ["queued", "processing"]

        results: List[Dict[str, Any]] = []
        checked = 0

        for st in statuses:
            last_evaluated_key = None
            processed_for_status = 0

            while processed_for_status < per_status_limit:
                # Lambda残り時間をチェック
                if context.get_remaining_time_in_millis() < SAFETY_MILLIS:
                    logger.warning(f"Lambda timeout approaching, terminating polling")
                    break

                # status-index: PK=statusでQuery。anthropic_batch_idがあるものに限定
                resp = table.query(
                    IndexName=DDB_STATUS_INDEX_NAME,
                    KeyConditionExpression=Key("status").eq(st),
                    FilterExpression=Attr("anthropic_batch_id").exists(),
                    Limit=min(50, per_status_limit - processed_for_status),
                    ExclusiveStartKey=last_evaluated_key,
                )

                items = resp.get("Items", [])
                if not items:
                    break

                for item in items:
                    run_id = item.get("batch_id")
                    if not run_id:
                        continue
                    res = check_and_update_batch_status(run_id, context)
                    results.append(res)
                    checked += 1
                    processed_for_status += 1

                    # Lambda残り時間をチェック
                    if context.get_remaining_time_in_millis() < SAFETY_MILLIS:
                        break

                last_evaluated_key = resp.get("LastEvaluatedKey")
                if not last_evaluated_key:
                    break

            # Lambda残り時間をチェック
            if context.get_remaining_time_in_millis() < SAFETY_MILLIS:
                break

        response_data = {
            "scheduled_polling": True,
            "checked_batches": checked,
            "results": results,
            "checked_at": _now_iso(),
        }
        
        logger.info(f"定期ポーリング完了: {response_data['checked_batches']}件をチェックしました")
        return success_response(response_data)

    except Exception as e:
        logger.error(f"定期ポーリング処理に失敗しました: {str(e)} ({type(e).__name__})")
        return handle_error(e, "Failed to process scheduled polling")

def handle_direct_invocation(event: Dict[str, Any], context) -> Dict[str, Any]:
    """
    直接実行（テスト/手動再チェック用）
    event = {"run_id": "..."}
    """
    run_id = event.get("run_id")
    if not run_id:
        return handle_error(ValueError("run_id is required for direct invocation"), "Direct invocation requires run_id")

    logger.info(f"直接実行によるバッチ状態チェック: run_id={run_id}")
    res = check_and_update_batch_status(run_id, context)
    return success_response(res)

def check_and_update_batch_status(run_id: str, context) -> Dict[str, Any]:
    """
    Anthropicのバッチ状態を確認し、必要に応じて結果をS3保存 → DDB更新
    """
    state_manager: Optional[BatchStateManager] = None

    try:
        logger.info(f"バッチ状態チェック開始: run_id={run_id}")

        # 現在のレコード取得（GSI: batch_id-index）
        batch_record = get_batch_record_from_db(run_id)
        if not batch_record["success"]:
            return {"success": False, "run_id": run_id, "error": batch_record["error"]}

        batch_data = batch_record["data"]
        anthropic_batch_id = batch_data.get("anthropic_batch_id")
        if not anthropic_batch_id:
            return {"success": False, "run_id": run_id, "error": "Anthropic batch IDが見つかりません"}

        # 状態の復元
        current_status = BatchStatus(batch_data.get("status", "queued"))
        state_manager = BatchStateManager(current_status)

        # 既存の状態データから復元を試行
        state_key = "state_manager" if "state_manager" in batch_data else "state_machine"
        if state_key in batch_data:
            try:
                state_manager = BatchStateManager.from_dict(batch_data[state_key])
            except Exception as e:
                logger.warning(f"状態データの復元に失敗しました: run_id={run_id}, error={str(e)}")

        # Anthropicへ問い合わせ
        status_result = get_anthropic_batch_status(anthropic_batch_id, run_id)
        if not status_result["success"]:
            error = classify_error(Exception(status_result["error"]))
            state_manager.add_error(error)
            update_batch_status_with_state(run_id, state_manager, batch_data)
            return {"success": False, "run_id": run_id, "error": status_result["error"]}

        anthropic_status = status_result["status"]
        anthropic_data = status_result["data"]

        status_changed = False

        if anthropic_status in ["completed", "expired", "failed", "cancelled"]:
            if anthropic_status == "completed":
                # 結果をS3に保存
                saved = save_batch_results_to_s3(anthropic_batch_id, run_id, anthropic_data)
                if saved["success"]:
                    state_manager.transition_to(
                        BatchStatus.COMPLETED,
                        "バッチ処理が正常に完了しました",
                        {
                            "anthropic_status": anthropic_status,
                            "results_location": saved["s3_key"],
                            "total_results": saved.get("total_results", 0),
                        },
                    )
                else:
                    err = ProcessingError(ErrorType.RETRIABLE, f"結果の保存に失敗しました: {saved['error']}")
                    state_manager.add_error(err)
                    if state_manager.should_retry():
                        state_manager.transition_to(BatchStatus.RETRYING, "結果保存を再試行します")
                    else:
                        state_manager.transition_to(BatchStatus.FAILED, "結果保存に失敗しました")
                status_changed = True

            elif anthropic_status == "failed":
                err = ProcessingError(
                    ErrorType.PERMANENT,
                    f"Anthropicバッチ処理が失敗しました: {_to_dict_safe(anthropic_data.get('error', 'Unknown error'))}",
                )
                state_manager.add_error(err)
                state_manager.transition_to(BatchStatus.FAILED, "Anthropicバッチ処理が失敗しました")
                status_changed = True

            elif anthropic_status in ["expired", "cancelled"]:
                state_manager.transition_to(BatchStatus.CANCELLED, f"Anthropicバッチが{anthropic_status}になりました")
                status_changed = True

        elif anthropic_status == "in_progress":
            # 状態維持。last_checked_atを更新するためにDDBは更新する
            logger.info(f"バッチ処理継続中: run_id={run_id}")

        # DDB更新（last_checked_at / updated_at / retry_countなどを反映）
        update_result = update_batch_status_with_state(run_id, state_manager, batch_data)

        return {
            "success": True,
            "run_id": run_id,
            "anthropic_batch_id": anthropic_batch_id,
            "anthropic_status": anthropic_status,
            "updated_status": state_manager.current_status.value,
            "status_changed": status_changed,
            "db_updated": update_result["success"],
        }

    except Exception as e:
        logger.error(f"バッチ状態チェック中に予期しないエラーが発生しました: run_id={run_id}, error={str(e)} ({type(e).__name__})")
        if state_manager:
            error = classify_error(e)
            state_manager.add_error(error)
            state_manager.transition_to(BatchStatus.FAILED, f"予期しないエラー: {str(e)}")
            update_batch_status_with_state(run_id, state_manager, {})
        return {"success": False, "run_id": run_id, "error": str(e)}

def get_batch_record_from_db(run_id: str) -> Dict[str, Any]:
    """
    GSI(batch_id-index)で1件取得（scan排除）
    """
    try:
        table = get_dynamodb_table()
        resp = table.query(
            IndexName=DDB_BATCH_ID_INDEX_NAME,
            KeyConditionExpression=Key("batch_id").eq(run_id),
            Limit=1,
        )
        items = resp.get("Items", [])
        if not items:
            return {"success": False, "error": "バッチレコードが見つかりません"}
        return {"success": True, "data": items[0]}
    except Exception as e:
        logger.error(f"DynamoDB取得エラー: run_id={run_id}, error={str(e)} ({type(e).__name__})")
        return {"success": False, "error": str(e)}

def update_batch_status_with_state(
    run_id: str,
    state_manager: BatchStateManager,
    existing_data: Dict[str, Any],
) -> Dict[str, Any]:
    """
    状態管理のスナップショットと監視用タイムスタンプをDDBに反映
    - updated_at / last_checked_atはUTC ISO8601
    - 既存アイテムが無い場合はエラー（誤生成防止）
    """
    try:
        table = get_dynamodb_table()
        job_id = existing_data.get("job_id")
        if not job_id:
            logger.error(f"既存データにjob_idが見つかりません: run_id={run_id}")
            return {"success": False, "error": "Job IDが見つかりません"}

        now = _now_iso()

        update_expression = """
            SET #status = :status,
                updated_at = :updated_at,
                last_checked_at = :last_checked_at,
                state_manager = :state_manager,
                duration_seconds = :duration,
                retry_count = :retry_count
        """

        expression_attribute_names = {"#status": "status"}
        expression_attribute_values = {
            ":status": state_manager.current_status.value,
            ":updated_at": now,
            ":last_checked_at": now,
            ":state_manager": state_manager.to_dict(),
            ":duration": state_manager.get_duration(),
            ":retry_count": state_manager.get_retry_count(),
        }

        table.update_item(
            Key={"job_id": job_id, "batch_id": run_id},
            UpdateExpression=update_expression,
            ExpressionAttributeNames=expression_attribute_names,
            ExpressionAttributeValues=expression_attribute_values,
            ConditionExpression="attribute_exists(job_id) AND attribute_exists(batch_id)",
            ReturnValues="NONE",
        )

        logger.info(f"DynamoDB更新完了: run_id={run_id}, job_id={job_id}, "
                   f"status={state_manager.current_status.value}, retry_count={state_manager.get_retry_count()}")
        return {"success": True, "job_id": job_id, "batch_id": run_id}

    except Exception as e:
        logger.error(f"DynamoDB更新エラー: run_id={run_id}, error={str(e)} ({type(e).__name__})")
        return {"success": False, "error": str(e)}

def get_anthropic_batch_status(anthropic_batch_id: str, run_id: str) -> Dict[str, Any]:
    """
    Anthropic Batch APIからステータスを取得
    """
    try:
        logger.info(f"Anthropicステータス取得: run_id={run_id}, anthropic_batch_id={anthropic_batch_id}")
        client = Anthropic(api_key=get_anthropic_api_key())
        batch = client.beta.messages.batches.retrieve(anthropic_batch_id)

        return {
            "success": True,
            "status": batch.status,
            "data": {
                "id": batch.id,
                "status": batch.status,
                "request_counts": _to_dict_safe(getattr(batch, "request_counts", {})),
                "results_url": getattr(batch, "results_url", None),
                "created_at": getattr(batch, "created_at", None),
                "processing_data": _to_dict_safe(getattr(batch, "processing_data", {})),
                "expires_at": getattr(batch, "expires_at", None),
            },
        }
    except Exception as e:
        error_msg = f"Anthropicバッチステータス取得に失敗しました: {str(e)}"
        logger.error(f"{error_msg} ({type(e).__name__}), run_id={run_id}")
        return {"success": False, "error": error_msg}


def save_batch_results_to_s3(anthropic_batch_id: str, run_id: str, anthropic_data: Dict) -> Dict[str, Any]:
    """
    結果をJSONLでS3へ保存（現状は全件メモリ結合。大規模化したらストリーミングに変更推奨）
    """
    try:
        logger.info(f"バッチ結果をS3に保存開始: run_id={run_id}, anthropic_batch_id={anthropic_batch_id}")
        
        client = Anthropic(api_key=get_anthropic_api_key())
        results = client.beta.messages.batches.results(anthropic_batch_id)

        bucket = get_required_env("LLM_PIPELINE_BUCKET")
        results_key = f"batches/{run_id}/results.jsonl"
        metadata_key = f"batches/{run_id}/completed_metadata.json"

        results_content = []
        total_results = 0
        for r in results:
            results_content.append(json.dumps(_to_dict_safe(r), ensure_ascii=False, default=str))
            total_results += 1

        # JSONLとして保存
        put_s3_object_with_lifecycle(
            bucket=bucket,
            key=results_key,
            body="\n".join(results_content) + ("\n" if results_content else ""),
            content_type="application/x-ndjson",
            retention_days=365,
        )

        completed_metadata = {
            "run_id": run_id,
            "anthropic_batch_id": anthropic_batch_id,
            # created_atは「作成時刻」なので完了時刻とは限らない。無ければnowを入れる
            "completed_at": anthropic_data.get("completed_at") or _now_iso(),
            "total_results": total_results,
            "request_counts": anthropic_data.get("request_counts", {}),
            "results_location": {"bucket": bucket, "key": results_key},
        }

        put_s3_object_with_lifecycle(
            bucket=bucket,
            key=metadata_key,
            body=json.dumps(completed_metadata, ensure_ascii=False, default=str),
            retention_days=365,
        )

        logger.info(f"バッチ結果S3保存完了: run_id={run_id}, key={results_key}, total_results={total_results}")
        return {"success": True, "s3_key": results_key, "metadata_key": metadata_key, "total_results": total_results}

    except Exception as e:
        error_msg = f"バッチ結果のS3保存に失敗しました: {str(e)}"
        logger.error(f"{error_msg} ({type(e).__name__}), run_id={run_id}")
        return {"success": False, "error": error_msg}
