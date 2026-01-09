from __future__ import annotations

import hashlib
import threading
import uuid
from collections.abc import Iterable, Mapping, Sequence
from dataclasses import dataclass
from urllib.parse import parse_qs, urlparse

from src.domain.object_store import CompletedPart, ObjectHead, ObjectStore


@dataclass(frozen=True)
class _ParsedFakeUrl:
    object_key: str
    method: str
    upload_id: str | None
    part_number: int | None


def _etag_for_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _parse_fake_url(url: str) -> _ParsedFakeUrl:
    parsed = urlparse(url)
    object_key = parsed.path.lstrip("/")
    q = parse_qs(parsed.query)
    method = str((q.get("method") or [""])[0]).upper()
    upload_id = str((q.get("upload_id") or [""])[0]).strip() or None
    part_raw = str((q.get("part_number") or [""])[0]).strip()
    part_number = int(part_raw) if part_raw.isdigit() else None
    return _ParsedFakeUrl(
        object_key=object_key,
        method=method,
        upload_id=upload_id,
        part_number=part_number,
    )


@dataclass
class _MultipartUpload:
    object_key: str
    parts: dict[int, bytes]


class FakeObjectStore(ObjectStore):
    """In-memory object store with fake presigned URLs (for tests only)."""

    def __init__(self, *, url_base: str = "fake://object"):
        self._url_base = url_base.rstrip("/")
        self._lock = threading.Lock()
        self._objects: dict[str, bytes] = {}
        self._multipart: dict[str, _MultipartUpload] = {}

    def presign_put(
        self,
        *,
        object_key: str,
        expires_in_seconds: int,
        content_type: str | None,
    ) -> str:
        _ = (expires_in_seconds, content_type)
        return f"{self._url_base}/{object_key}?method=PUT"

    def create_multipart_upload(self, *, object_key: str, content_type: str | None) -> str:
        _ = content_type
        upload_id = uuid.uuid4().hex
        with self._lock:
            self._multipart[upload_id] = _MultipartUpload(object_key=object_key, parts={})
        return upload_id

    def presign_upload_part(
        self,
        *,
        object_key: str,
        upload_id: str,
        part_number: int,
        expires_in_seconds: int,
    ) -> str:
        _ = (expires_in_seconds,)
        with self._lock:
            upload = self._multipart.get(upload_id)
        if upload is None or upload.object_key != object_key:
            return (
                f"{self._url_base}/{object_key}"
                f"?method=PUT&upload_id=missing&part_number={part_number}"
            )
        return (
            f"{self._url_base}/{object_key}"
            f"?method=PUT&upload_id={upload_id}&part_number={part_number}"
        )

    def complete_multipart_upload(
        self,
        *,
        object_key: str,
        upload_id: str,
        parts: Sequence[CompletedPart],
    ) -> str:
        with self._lock:
            upload = self._multipart.get(upload_id)
            if upload is None or upload.object_key != object_key:
                raise KeyError(f"multipart upload not found: {upload_id}")
            part_bytes = dict(upload.parts)
            del self._multipart[upload_id]

        ordered: list[bytes] = []
        for item in sorted(parts, key=lambda p: p.part_number):
            data = part_bytes.get(item.part_number)
            if data is None:
                raise KeyError(f"multipart missing part: {upload_id}:{item.part_number}")
            ordered.append(data)
        combined = b"".join(ordered)
        with self._lock:
            self._objects[object_key] = combined
        return _etag_for_bytes(combined)

    def abort_multipart_upload(self, *, object_key: str, upload_id: str) -> None:
        _ = object_key
        with self._lock:
            self._multipart.pop(upload_id, None)

    def head_object(self, *, object_key: str) -> ObjectHead | None:
        with self._lock:
            data = self._objects.get(object_key)
        if data is None:
            return None
        return ObjectHead(size_bytes=len(data), etag=_etag_for_bytes(data))

    def read_bytes(self, *, object_key: str) -> bytes:
        with self._lock:
            data = self._objects.get(object_key)
        if data is None:
            raise KeyError(f"object not found: {object_key}")
        return data

    def iter_bytes(self, *, object_key: str, chunk_size: int = 1024 * 1024) -> Iterable[bytes]:
        data = self.read_bytes(object_key=object_key)
        for offset in range(0, len(data), chunk_size):
            yield data[offset : offset + chunk_size]

    def put_via_presigned_url(self, *, url: str, data: bytes) -> str:
        parsed = _parse_fake_url(url)
        if parsed.method != "PUT":
            raise ValueError(f"unsupported method: {parsed.method}")

        if parsed.upload_id is None:
            with self._lock:
                self._objects[parsed.object_key] = data
            return _etag_for_bytes(data)

        if parsed.part_number is None:
            raise ValueError("multipart part_number is required")

        with self._lock:
            upload = self._multipart.get(parsed.upload_id)
            if upload is None or upload.object_key != parsed.object_key:
                raise KeyError(f"multipart upload not found: {parsed.upload_id}")
            upload.parts[parsed.part_number] = data
        return _etag_for_bytes(data)

    def debug_snapshot(self) -> Mapping[str, object]:
        with self._lock:
            return {
                "objects": {k: len(v) for k, v in self._objects.items()},
                "multipart_uploads": {
                    k: {"object_key": u.object_key, "parts": sorted(u.parts.keys())}
                    for k, u in self._multipart.items()
                },
            }
