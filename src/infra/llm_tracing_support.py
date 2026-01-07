from __future__ import annotations

import hashlib
import re
from datetime import datetime

LLM_META_SCHEMA_VERSION_V1 = 1

_REDACTIONS: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"(?i)(authorization\\s*:\\s*bearer)\\s+[^\\s]+"), r"\\1 <REDACTED>"),
    (re.compile(r"sk-[A-Za-z0-9]{20,}"), "sk-<REDACTED>"),
    (
        re.compile(r"(?i)\\b(api[_-]?key|token|secret|password)\\b\\s*[:=]\\s*[^\\s,;]+"),
        r"\\1=<REDACTED>",
    ),
    (re.compile(r"/home/[^\\s]+"), "/home/<REDACTED>"),
    (re.compile(r"/Users/[^\\s]+"), "/Users/<REDACTED>"),
]


def redact_text(text: str) -> str:
    value = text
    for pattern, replacement in _REDACTIONS:
        value = pattern.sub(replacement, value)
    return value


def sha256_hex(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8", errors="ignore")).hexdigest()


def estimate_tokens(text: str) -> int:
    stripped = text.strip()
    if stripped == "":
        return 0
    return max(1, len(stripped) // 4)


def llm_call_id(*, operation: str, started_at: datetime, prompt_fingerprint: str) -> str:
    ts = started_at.strftime("%Y%m%dT%H%M%S") + f"{started_at.microsecond:06d}Z"
    return f"{operation}-{ts}-{prompt_fingerprint[:12]}"

