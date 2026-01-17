from __future__ import annotations

from typing import Any

from ss_ssh_e2e.errors import E2EError, redact


def http_json(resp: Any) -> Any:
    try:
        return resp.json()
    except ValueError:
        return {"_raw": resp.text}


def assert_status(resp: Any, *, expected: int, context: str) -> None:
    if resp.status_code == expected:
        return
    raise E2EError(
        event_code="SSE2E_HTTP_UNEXPECTED",
        message=f"{context}: status={resp.status_code}",
        details={"body": redact(http_json(resp))},
    )

