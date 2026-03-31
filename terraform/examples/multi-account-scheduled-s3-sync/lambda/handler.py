"""Minimal S3 copy sample: first page of keys from source to destination.

Extend with pagination, prefix filters, cross-account credentials, etc.
"""

from __future__ import annotations

import os

import boto3

SOURCE_BUCKET = os.environ["SOURCE_BUCKET"]
DESTINATION_BUCKET = os.environ["DESTINATION_BUCKET"]


def lambda_handler(event: object, context: object) -> dict[str, object]:
    client = boto3.client("s3")
    resp = client.list_objects_v2(Bucket=SOURCE_BUCKET, MaxKeys=50)
    for obj in resp.get("Contents", []):
        key = obj["Key"]
        copy_source = {"Bucket": SOURCE_BUCKET, "Key": key}
        client.copy_object(
            CopySource=copy_source,
            Bucket=DESTINATION_BUCKET,
            Key=key,
        )
    return {"statusCode": 200, "copied": len(resp.get("Contents", []))}
