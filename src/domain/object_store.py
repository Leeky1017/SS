from __future__ import annotations

from collections.abc import Iterable, Sequence
from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True)
class ObjectHead:
    size_bytes: int
    etag: str | None = None


@dataclass(frozen=True)
class CompletedPart:
    part_number: int
    etag: str


class ObjectStore(Protocol):
    def presign_put(
        self,
        *,
        object_key: str,
        expires_in_seconds: int,
        content_type: str | None,
    ) -> str: ...

    def create_multipart_upload(self, *, object_key: str, content_type: str | None) -> str: ...

    def presign_upload_part(
        self,
        *,
        object_key: str,
        upload_id: str,
        part_number: int,
        expires_in_seconds: int,
    ) -> str: ...

    def complete_multipart_upload(
        self,
        *,
        object_key: str,
        upload_id: str,
        parts: Sequence[CompletedPart],
    ) -> str: ...

    def abort_multipart_upload(self, *, object_key: str, upload_id: str) -> None: ...

    def head_object(self, *, object_key: str) -> ObjectHead | None: ...

    def read_bytes(self, *, object_key: str) -> bytes: ...

    def iter_bytes(self, *, object_key: str, chunk_size: int = 1024 * 1024) -> Iterable[bytes]: ...

