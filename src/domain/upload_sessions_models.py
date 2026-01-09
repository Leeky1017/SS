from __future__ import annotations

from dataclasses import dataclass
from typing import Any, cast

from src.infra.upload_session_exceptions import UploadSessionCorruptedError
from src.utils.json_types import JsonObject


def _require_str(*, payload: JsonObject, key: str, upload_session_id: str) -> str:
    value = payload.get(key)
    if not isinstance(value, str) or value.strip() == "":
        raise UploadSessionCorruptedError(upload_session_id=upload_session_id)
    return value


def _require_int(*, payload: JsonObject, key: str, upload_session_id: str) -> int:
    value = payload.get(key)
    if not isinstance(value, int):
        raise UploadSessionCorruptedError(upload_session_id=upload_session_id)
    return int(value)


def _optional_str(*, payload: JsonObject, key: str, upload_session_id: str) -> str | None:
    value = payload.get(key)
    if value is None:
        return None
    if not isinstance(value, str):
        raise UploadSessionCorruptedError(upload_session_id=upload_session_id)
    candidate = value.strip()
    return None if candidate == "" else candidate


def _optional_int(*, payload: JsonObject, key: str, upload_session_id: str) -> int | None:
    value = payload.get(key)
    if value is None:
        return None
    if not isinstance(value, int):
        raise UploadSessionCorruptedError(upload_session_id=upload_session_id)
    return int(value)


def _optional_finalize(
    *, payload: JsonObject, upload_session_id: str
) -> FinalizeSuccessPayload | None:
    finalize_obj = payload.get("finalize")
    if finalize_obj is None:
        return None
    if not isinstance(finalize_obj, dict):
        raise UploadSessionCorruptedError(upload_session_id=upload_session_id)
    return FinalizeSuccessPayload.from_payload(
        upload_session_id=upload_session_id,
        payload=finalize_obj,
    )


@dataclass(frozen=True)
class FinalizeSuccessPayload:
    success: bool
    status: str
    upload_session_id: str
    file_id: str
    sha256: str
    size_bytes: int

    def to_payload(self) -> JsonObject:
        return cast(
            JsonObject,
            {
                "success": True,
                "status": self.status,
                "upload_session_id": self.upload_session_id,
                "file_id": self.file_id,
                "sha256": self.sha256,
                "size_bytes": self.size_bytes,
            },
        )

    @staticmethod
    def from_payload(*, upload_session_id: str, payload: JsonObject) -> FinalizeSuccessPayload:
        if payload.get("success") is not True:
            raise UploadSessionCorruptedError(upload_session_id=upload_session_id)
        status = _require_str(payload=payload, key="status", upload_session_id=upload_session_id)
        file_id = _require_str(payload=payload, key="file_id", upload_session_id=upload_session_id)
        sha256 = _require_str(payload=payload, key="sha256", upload_session_id=upload_session_id)
        size_bytes = _require_int(
            payload=payload,
            key="size_bytes",
            upload_session_id=upload_session_id,
        )
        return FinalizeSuccessPayload(
            success=True,
            status=status,
            upload_session_id=upload_session_id,
            file_id=file_id,
            sha256=sha256,
            size_bytes=size_bytes,
        )


@dataclass(frozen=True)
class UploadSessionRecord:
    upload_session_id: str
    job_id: str
    bundle_id: str
    file_id: str
    role: str
    original_name: str
    size_bytes: int
    content_type: str | None
    upload_strategy: str
    object_key: str
    upload_id: str | None
    part_size: int | None
    part_count: int | None
    created_at: str
    expires_at: str
    finalized: FinalizeSuccessPayload | None

    def to_payload(self) -> JsonObject:
        payload: dict[str, Any] = {
            "upload_session_id": self.upload_session_id,
            "job_id": self.job_id,
            "bundle_id": self.bundle_id,
            "file_id": self.file_id,
            "role": self.role,
            "original_name": self.original_name,
            "size_bytes": self.size_bytes,
            "content_type": self.content_type,
            "upload_strategy": self.upload_strategy,
            "object_key": self.object_key,
            "upload_id": self.upload_id,
            "part_size": self.part_size,
            "part_count": self.part_count,
            "created_at": self.created_at,
            "expires_at": self.expires_at,
            "finalize": None if self.finalized is None else self.finalized.to_payload(),
        }
        return cast(JsonObject, payload)

    @staticmethod
    def from_payload(*, upload_session_id: str, payload: JsonObject) -> UploadSessionRecord:
        job_id = _require_str(payload=payload, key="job_id", upload_session_id=upload_session_id)
        bundle_id = _require_str(
            payload=payload,
            key="bundle_id",
            upload_session_id=upload_session_id,
        )
        file_id = _require_str(payload=payload, key="file_id", upload_session_id=upload_session_id)
        role = _require_str(payload=payload, key="role", upload_session_id=upload_session_id)
        original_name = _require_str(
            payload=payload,
            key="original_name",
            upload_session_id=upload_session_id,
        )
        size_bytes = _require_int(
            payload=payload,
            key="size_bytes",
            upload_session_id=upload_session_id,
        )
        content_type = _optional_str(
            payload=payload,
            key="content_type",
            upload_session_id=upload_session_id,
        )
        upload_strategy = _require_str(
            payload=payload,
            key="upload_strategy",
            upload_session_id=upload_session_id,
        )
        object_key = _require_str(
            payload=payload,
            key="object_key",
            upload_session_id=upload_session_id,
        )
        upload_id = _optional_str(
            payload=payload,
            key="upload_id",
            upload_session_id=upload_session_id,
        )
        part_size = _optional_int(
            payload=payload,
            key="part_size",
            upload_session_id=upload_session_id,
        )
        part_count = _optional_int(
            payload=payload,
            key="part_count",
            upload_session_id=upload_session_id,
        )
        created_at = _require_str(
            payload=payload,
            key="created_at",
            upload_session_id=upload_session_id,
        )
        expires_at = _require_str(
            payload=payload,
            key="expires_at",
            upload_session_id=upload_session_id,
        )
        finalized = _optional_finalize(payload=payload, upload_session_id=upload_session_id)
        return UploadSessionRecord(
            upload_session_id=upload_session_id,
            job_id=job_id,
            bundle_id=bundle_id,
            file_id=file_id,
            role=role,
            original_name=original_name,
            size_bytes=size_bytes,
            content_type=content_type,
            upload_strategy=upload_strategy,
            object_key=object_key,
            upload_id=upload_id,
            part_size=part_size,
            part_count=part_count,
            created_at=created_at,
            expires_at=expires_at,
            finalized=finalized,
        )
