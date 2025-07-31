"""
LLM Batch Preparer Lambda Function

LLMバッチリクエストを準備・管理するRESTful API Lambda関数です。

機能:
- バッチジョブの登録 (POST /llm-service/runs/)
- バッチジョブの一覧取得 (GET /llm-service/runs/)
- 特定ジョブのステータス取得 (GET /llm-service/runs/{run_id})
"""

import json
import logging
import os
from typing import Any, Dict
from datetime import datetime, timezone

from boto3.dynamodb.conditions import Attr, Key

from common import (
    cors_preflight_response,
    created_response,
    error_response,
    get_dynamodb_table,
    get_required_env,
    get_sqs_client,
    handle_error,
    not_found_response,
    success_response,
    validation_error_response,
)

# ログ設定：AWS Lambdaの自動設定を利用
logger = logging.getLogger(__name__)
log_level = os.environ.get("LOG_LEVEL", "INFO").upper()
logger.setLevel(getattr(logging, log_level, logging.INFO))


def handler(event: Dict[str, Any], context) -> Dict[str, Any]:
    """
    API Gatewayからのリクエストを処理するLambdaハンドラー。
    """
    try:
        logger.info(f"受信イベント: {json.dumps(event)}")
        
        http_method = (event.get("httpMethod") or "").upper()
        resource = event.get("resource") or (event.get("requestContext", {}).get("resourcePath") or "")

        if http_method == "OPTIONS":
            return cors_preflight_response()

        if resource == "/llm-service/runs":
            if http_method == "POST":
                return handle_register_run(event, context)
            if http_method == "GET":
                return handle_list_runs(event)
            return error_response("エンドポイントが見つかりません", 404)

        elif resource == "/llm-service/runs/{run_id}" and http_method == "GET":
            return handle_get_run_status(event)

        else:
            return error_response("エンドポイントが見つかりません", 404)

    except Exception as e:
        return handle_error(e, "リクエスト処理に失敗しました")


def handle_register_run(event: Dict[str, Any], context) -> Dict[str, Any]:
    """
    新しいバッチジョブを登録します。
    """
    try:
        body = event.get("body")
        if not body:
            return validation_error_response("リクエストボディが必要です")

        try:
            data = json.loads(body)
        except json.JSONDecodeError as e:
            logger.error(f"JSON decode error: {str(e)}")
            return validation_error_response("無効なJSON形式です")

        if not isinstance(data, dict):
            return validation_error_response("リクエストボディはJSONオブジェクトである必要があります")
            
        if "job_id" not in data:
            return validation_error_response("job_idが必要です")
        if "run_id" not in data:
            return validation_error_response("run_idが必要です")

        job_id = str(data["job_id"]).strip()
        run_id = str(data["run_id"]).strip()
        
        if not job_id:
            return validation_error_response("job_idを空にすることはできません")
        if not run_id:
            return validation_error_response("run_idを空にすることはできません")
            
        logger.info(f"登録処理開始: job_id={job_id}, run_id={run_id}")

        timestamp = datetime.now(timezone.utc).isoformat()
        item = {
            "job_id": job_id,
            "batch_id": run_id,
            "status": "queued",
            # "request_object": data.get("request_object", {}),
            # "result_reference": data.get("result_reference"),
            # "callback_url": data.get("callback_url"),
            # "created_at": timestamp,
            # "updated_at": timestamp,
        }

        table = get_dynamodb_table()
        table.put_item(Item=item)
        logger.info(f"DynamoDB保存成功: job_id={job_id}, run_id={run_id}")

        sqs = get_sqs_client()
        queue_url = get_required_env("SQS_QUEUE_URL")
        if not queue_url.startswith("https://"):
            raise RuntimeError(f"SQS_QUEUE_URLが正しくありません: {queue_url!r}")

        message_body = {
            # "job_id": job_id,
            "run_id": run_id,
        }

        resp = sqs.send_message(
            QueueUrl=queue_url,
            MessageBody=json.dumps(message_body),
            MessageAttributes={
                "run_id": {"StringValue": run_id, "DataType": "String"},
                "job_id": {"StringValue": job_id, "DataType": "String"},
            },
            MessageGroupId=job_id,
            MessageDeduplicationId=run_id,
        )
        logger.info(f"SQSメッセージ送信成功: MessageId={resp.get('MessageId')}, run_id={run_id}")

        response_data = {
            "job_id": job_id,
            "run_id": run_id,
            "status": "queued",
            "created_at": timestamp
        }

        return created_response(response_data)

    except Exception as e:
        logger.error(f"実行登録に失敗しました: {str(e)} ({type(e).__name__})")
        return handle_error(e, "Failed to register run")


def handle_list_runs(event: Dict[str, Any]) -> Dict[str, Any]:
    """
    バッチジョブの一覧を取得します。
    """
    try:
        params = event.get("queryStringParameters") or {}
        job_id = params.get("job_id")
        logger.info(f"job_idフィルター付きで実行一覧を取得: {job_id}")

        table = get_dynamodb_table()

        if job_id:
            response = table.query(KeyConditionExpression=Key("job_id").eq(job_id))
        else:
            response = table.scan()

        runs = [
            {
                "job_id": item["job_id"],
                "run_id": item["batch_id"],
                "status": item.get("status", "unknown"),
                "created_at": item.get("created_at"),
                "updated_at": item.get("updated_at"),
            }
            for item in response.get("Items", [])
        ]

        logger.info(f"{len(runs)}件の実行を発見しました")
        return success_response(runs)

    except Exception as e:
        logger.error(f"実行一覧取得に失敗しました: {str(e)} ({type(e).__name__})")
        return handle_error(e, "Failed to list runs")


def handle_get_run_status(event: Dict[str, Any]) -> Dict[str, Any]:
    """
    特定のバッチジョブのステータスを取得します。
    """
    try:
        path_params = event.get("pathParameters") or {}
        run_id = path_params.get("run_id")

        if not run_id:
            return validation_error_response("run_idが必要です")

        query_params = event.get("queryStringParameters") or {}
        job_id = query_params.get("job_id")
        
        logger.info(f"実行状態取得: run_id={run_id}, job_id={job_id}")

        table = get_dynamodb_table()

        if job_id:
            response = table.get_item(Key={"job_id": job_id, "batch_id": run_id})
            item = response.get("Item")
        else:
            scan_response = table.scan(FilterExpression=Attr("batch_id").eq(run_id))
            items = scan_response.get("Items", [])
            item = items[0] if items else None

        if not item:
            logger.warning(f"実行が見つかりません: run_id={run_id}")
            return not_found_response("実行が見つかりません")

        run_data = {
            "job_id": item["job_id"],
            "run_id": item["batch_id"],
            "status": item.get("status", "unknown"),
            "created_at": item.get("created_at"),
            # "updated_at": item.get("updated_at"),
            # "request_object": item.get("request_object"),
            # "result_reference": item.get("result_reference"),
        }

        logger.info(f"実行状態取得成功: {run_data['status']}")
        return success_response(run_data)

    except Exception as e:
        logger.error(f"実行状態取得に失敗しました: {str(e)} ({type(e).__name__})")
        return handle_error(e, "Failed to get run status")