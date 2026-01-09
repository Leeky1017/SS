from __future__ import annotations

from collections.abc import Iterable, Sequence

import boto3
from botocore.config import Config as BotoConfig
from botocore.exceptions import BotoCoreError, ClientError

from src.config import Config
from src.domain.object_store import CompletedPart, ObjectHead, ObjectStore
from src.infra.object_store_exceptions import (
    ObjectStoreConfigurationError,
    ObjectStoreOperationFailedError,
)

_BOTO_ERRORS = (ClientError, BotoCoreError)


def _require_value(value: str, *, label: str) -> str:
    candidate = value.strip()
    if candidate == "":
        raise ObjectStoreConfigurationError(message=f"missing {label}")
    return candidate


class S3ObjectStore(ObjectStore):
    def __init__(self, *, client: object, bucket: str):
        self._client = client
        self._bucket = bucket

    @classmethod
    def from_config(cls, *, config: Config) -> "S3ObjectStore":
        endpoint_url = config.upload_s3_endpoint.strip() or None
        region_name = config.upload_s3_region.strip() or None
        bucket = _require_value(config.upload_s3_bucket, label="SS_UPLOAD_S3_BUCKET")
        access_key_id = _require_value(
            config.upload_s3_access_key_id,
            label="SS_UPLOAD_S3_ACCESS_KEY_ID",
        )
        secret_access_key = _require_value(
            config.upload_s3_secret_access_key,
            label="SS_UPLOAD_S3_SECRET_ACCESS_KEY",
        )
        session = boto3.session.Session(
            aws_access_key_id=access_key_id,
            aws_secret_access_key=secret_access_key,
            region_name=region_name,
        )
        client = session.client(
            "s3",
            endpoint_url=endpoint_url,
            config=BotoConfig(signature_version="s3v4"),
        )
        return cls(client=client, bucket=bucket)

    def presign_put(
        self,
        *,
        object_key: str,
        expires_in_seconds: int,
        content_type: str | None,
    ) -> str:
        params: dict[str, object] = {"Bucket": self._bucket, "Key": object_key}
        if content_type is not None and content_type.strip() != "":
            params["ContentType"] = content_type
        try:
            return str(
                self._client.generate_presigned_url(
                    "put_object",
                    Params=params,
                    ExpiresIn=expires_in_seconds,
                )
            )
        except _BOTO_ERRORS as exc:  # pragma: no cover
            raise ObjectStoreOperationFailedError(operation="presign_put") from exc

    def create_multipart_upload(self, *, object_key: str, content_type: str | None) -> str:
        kwargs: dict[str, object] = {"Bucket": self._bucket, "Key": object_key}
        if content_type is not None and content_type.strip() != "":
            kwargs["ContentType"] = content_type
        try:
            resp = self._client.create_multipart_upload(**kwargs)
            return str(resp["UploadId"])
        except _BOTO_ERRORS as exc:  # pragma: no cover
            raise ObjectStoreOperationFailedError(operation="create_multipart_upload") from exc

    def presign_upload_part(
        self,
        *,
        object_key: str,
        upload_id: str,
        part_number: int,
        expires_in_seconds: int,
    ) -> str:
        try:
            return str(
                self._client.generate_presigned_url(
                    "upload_part",
                    Params={
                        "Bucket": self._bucket,
                        "Key": object_key,
                        "UploadId": upload_id,
                        "PartNumber": part_number,
                    },
                    ExpiresIn=expires_in_seconds,
                )
            )
        except _BOTO_ERRORS as exc:  # pragma: no cover
            raise ObjectStoreOperationFailedError(operation="presign_upload_part") from exc

    def complete_multipart_upload(
        self,
        *,
        object_key: str,
        upload_id: str,
        parts: Sequence[CompletedPart],
    ) -> str:
        payload = {
            "Parts": [{"PartNumber": p.part_number, "ETag": p.etag} for p in parts],
        }
        try:
            resp = self._client.complete_multipart_upload(
                Bucket=self._bucket,
                Key=object_key,
                UploadId=upload_id,
                MultipartUpload=payload,
            )
            return str(resp.get("ETag", ""))
        except _BOTO_ERRORS as exc:  # pragma: no cover
            raise ObjectStoreOperationFailedError(operation="complete_multipart_upload") from exc

    def abort_multipart_upload(self, *, object_key: str, upload_id: str) -> None:
        try:
            self._client.abort_multipart_upload(
                Bucket=self._bucket,
                Key=object_key,
                UploadId=upload_id,
            )
        except _BOTO_ERRORS as exc:  # pragma: no cover
            raise ObjectStoreOperationFailedError(operation="abort_multipart_upload") from exc

    def head_object(self, *, object_key: str) -> ObjectHead | None:
        try:
            resp = self._client.head_object(Bucket=self._bucket, Key=object_key)
        except _BOTO_ERRORS:  # pragma: no cover
            return None
        return ObjectHead(
            size_bytes=int(resp.get("ContentLength", 0)),
            etag=str(resp.get("ETag", "")).strip() or None,
        )

    def read_bytes(self, *, object_key: str) -> bytes:
        try:
            resp = self._client.get_object(Bucket=self._bucket, Key=object_key)
            body = resp.get("Body")
            return b"" if body is None else body.read()
        except _BOTO_ERRORS as exc:  # pragma: no cover
            raise ObjectStoreOperationFailedError(operation="read_bytes") from exc

    def iter_bytes(self, *, object_key: str, chunk_size: int = 1024 * 1024) -> Iterable[bytes]:
        try:
            resp = self._client.get_object(Bucket=self._bucket, Key=object_key)
            body = resp.get("Body")
            if body is None:
                return iter(())
            return body.iter_chunks(chunk_size=chunk_size)
        except _BOTO_ERRORS as exc:  # pragma: no cover
            raise ObjectStoreOperationFailedError(operation="iter_bytes") from exc
