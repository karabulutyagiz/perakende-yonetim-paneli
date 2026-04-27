"""S3 presigned URL üretimi — mobil/web doğrudan S3'e upload eder."""
from uuid import uuid4

import boto3
from botocore.client import Config

from app.core.config import settings


def _client():
    return boto3.client(
        "s3",
        region_name=settings.aws_region,
        aws_access_key_id=settings.aws_access_key_id or None,
        aws_secret_access_key=settings.aws_secret_access_key or None,
        config=Config(signature_version="s3v4"),
    )


def generate_upload_url(filename: str, content_type: str) -> tuple[str, str]:
    """(upload_url, key) döndürür. PUT ile upload edilir."""
    ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else "bin"
    key = f"products/{uuid4().hex}.{ext}"

    url = _client().generate_presigned_url(
        ClientMethod="put_object",
        Params={
            "Bucket": settings.s3_bucket,
            "Key": key,
            "ContentType": content_type,
        },
        ExpiresIn=settings.s3_presign_expires,
    )
    return url, key


def get_public_url(key: str | None) -> str | None:
    if not key:
        return None
    return f"https://{settings.s3_bucket}.s3.{settings.aws_region}.amazonaws.com/{key}"


def generate_view_url(key: str | None) -> str | None:
    """Private bucket için kısa ömürlü GET URL'i."""
    if not key:
        return None
    return _client().generate_presigned_url(
        ClientMethod="get_object",
        Params={"Bucket": settings.s3_bucket, "Key": key},
        ExpiresIn=settings.s3_presign_expires,
    )
