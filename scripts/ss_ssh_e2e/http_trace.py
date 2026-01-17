from __future__ import annotations

from typing import Any

from ss_ssh_e2e.errors import redact


class HttpTrace:
    def __init__(self) -> None:
        self.calls: list[dict[str, Any]] = []

    def add(
        self,
        *,
        method: str,
        path: str,
        status_code: int,
        body: Any | None = None,
        extra: dict[str, Any] | None = None,
    ) -> None:
        entry: dict[str, Any] = {"method": method, "path": path, "status_code": status_code}
        if body is not None:
            entry["body"] = redact(body)
        if extra is not None:
            entry["extra"] = redact(extra)
        self.calls.append(entry)

