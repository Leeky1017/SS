from __future__ import annotations

import datetime as dt
import json
from pathlib import Path, PurePosixPath
from typing import Any


class E2EError(RuntimeError):
    def __init__(
        self,
        *,
        event_code: str,
        message: str,
        details: dict[str, Any] | None = None,
    ) -> None:
        super().__init__(f"{event_code} {message}")
        self.event_code = event_code
        self.details = details


def utc_ts() -> str:
    return dt.datetime.now(dt.UTC).strftime("%Y%m%dT%H%M%SZ")


def json_dumps(data: Any) -> str:
    return json.dumps(data, ensure_ascii=False, indent=2, sort_keys=True)


def redact(data: Any) -> Any:
    if isinstance(data, dict):
        out: dict[str, Any] = {}
        for key, value in data.items():
            if key.lower() in {"token", "authorization"}:
                out[key] = "<redacted>"
            else:
                out[key] = redact(value)
        return out
    if isinstance(data, list):
        return [redact(item) for item in data]
    return data


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def write_bytes(path: Path, content: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(content)


def safe_posix_rel_path(value: str) -> PurePosixPath:
    path = PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts:
        raise E2EError(event_code="SSE2E_UNSAFE_RELPATH", message=f"unsafe rel_path: {value!r}")
    return path
