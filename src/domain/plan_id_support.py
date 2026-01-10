from __future__ import annotations

import hashlib
import json
import re

from src.utils.json_types import JsonObject

_WHITESPACE_RE = re.compile(r"\s+")


def normalize_whitespace(value: str) -> str:
    return _WHITESPACE_RE.sub(" ", value.strip())


def sha256_hex(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8", errors="ignore")).hexdigest()


def build_plan_id(
    *,
    job_id: str,
    inputs_fingerprint: str,
    requirement: str,
    confirmation: JsonObject,
) -> str:
    canonical = json.dumps(
        {
            "v": 1,
            "job_id": job_id,
            "inputs_fingerprint": inputs_fingerprint,
            "requirement": requirement,
            "confirmation": confirmation,
        },
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )
    return sha256_hex(canonical)

