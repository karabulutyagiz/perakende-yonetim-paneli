"""S3 presigned URL üretimi — mobil/web doğrudan S3'e upload eder.

Local dev modunda (AWS_ACCESS_KEY_ID boşsa) S3 yerine backend'in kendi diskine
yazılır; upload/view URL'leri /api/v1/products/local-upload/{key} endpoint'lerine
döner.
"""
from uuid import uuid4

import boto3
from botocore.client import Config

from app.core.config import settings


def _is_local_mode() -> bool:
    """AWS credential yoksa local disk fallback'ı kullan."""
    return not (settings.aws_access_key_id and settings.aws_secret_access_key)


def _client():
    return boto3.client(
        "s3",
        region_name=settings.aws_region,
        aws_access_key_id=settings.aws_access_key_id or None,
        aws_secret_access_key=settings.aws_secret_access_key or None,
        config=Config(signature_version="s3v4"),
    )


def _local_base_url() -> str:
    """Backend host'u — production'da PUBLIC_API_BASE env'inden gelir."""
    if settings.public_api_base:
        return settings.public_api_base.rstrip("/")
    return f"http://localhost:{settings.backend_port}/api/v1"


def generate_upload_url(filename: str, content_type: str) -> tuple[str, str]:
    """(upload_url, key) döndürür. PUT ile upload edilir."""
    ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else "bin"
    key = f"products/{uuid4().hex}.{ext}"

    if _is_local_mode():
        # Local mode: backend'in kendi PUT endpoint'i
        return f"{_local_base_url()}/products/local-upload/{key}", key

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
    if _is_local_mode():
        return f"{_local_base_url()}/products/local-upload/{key}"
    return f"https://{settings.s3_bucket}.s3.{settings.aws_region}.amazonaws.com/{key}"


def generate_view_url(key: str | None) -> str | None:
    """Local'de: backend'den serve edilen direkt URL.
    Production: private bucket için kısa ömürlü GET URL."""
    if not key:
        return None
    if _is_local_mode():
        return f"{_local_base_url()}/products/local-upload/{key}"
    return _client().generate_presigned_url(
        ClientMethod="get_object",
        Params={"Bucket": settings.s3_bucket, "Key": key},
        ExpiresIn=settings.s3_presign_expires,
    )
