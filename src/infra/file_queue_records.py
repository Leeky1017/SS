from __future__ import annotations

import json
import logging
import os
import tempfile
from datetime import datetime, timedelta
from pathlib import Path

from src.domain.worker_queue import QueueClaim
from src.infra.exceptions import QueueDataCorruptedError, QueueIOError

logger = logging.getLogger(__name__)


def assert_safe_segment(value: str) -> None:
    if value == "":
        raise ValueError("path segment must not be empty")
    if "/" in value or "\\" in value:
        raise ValueError("path segment must not contain path separators")
    if value in {".", ".."}:
        raise ValueError("path segment must not traverse")


def atomic_write_json(*, path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    data = json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True)
    with tempfile.NamedTemporaryFile(
        "w",
        encoding="utf-8",
        dir=str(path.parent),
        delete=False,
    ) as f:
        f.write(data)
        tmp = Path(f.name)
    os.replace(tmp, path)


def read_queue_record(*, path: Path) -> dict:
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise
    except json.JSONDecodeError as e:
        logger.warning("SS_QUEUE_RECORD_CORRUPTED", extra={"path": str(path), "error": str(e)})
        raise QueueDataCorruptedError(path=str(path)) from e
    except OSError as e:
        logger.warning("SS_QUEUE_RECORD_READ_FAILED", extra={"path": str(path), "error": str(e)})
        raise QueueIOError(operation="read", path=str(path)) from e
    if not isinstance(raw, dict):
        raise QueueDataCorruptedError(path=str(path))
    return raw


def build_claim_fields(
    *,
    worker_id: str,
    claim_id: str,
    now: datetime,
    ttl: timedelta,
) -> dict:
    claimed_at = now.isoformat()
    lease_expires_at = (now + ttl).isoformat()
    return {
        "claim_id": claim_id,
        "worker_id": worker_id,
        "claimed_at": claimed_at,
        "lease_expires_at": lease_expires_at,
    }


def load_claim(*, record: dict) -> QueueClaim:
    job_id = str(record.get("job_id", ""))
    claim_id = str(record.get("claim_id", ""))
    worker_id = str(record.get("worker_id", ""))
    claimed_at = str(record.get("claimed_at", ""))
    lease_expires_at = str(record.get("lease_expires_at", ""))
    if (
        job_id == ""
        or claim_id == ""
        or worker_id == ""
        or claimed_at == ""
        or lease_expires_at == ""
    ):
        raise QueueDataCorruptedError(path="<record>")
    try:
        claimed_at_parsed = datetime.fromisoformat(claimed_at)
        lease_expires_at_parsed = datetime.fromisoformat(lease_expires_at)
    except ValueError as e:
        raise QueueDataCorruptedError(path="<record>") from e
    return QueueClaim(
        job_id=job_id,
        claim_id=claim_id,
        worker_id=worker_id,
        claimed_at=claimed_at_parsed,
        lease_expires_at=lease_expires_at_parsed,
    )

