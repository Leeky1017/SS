from __future__ import annotations

import logging
from collections import defaultdict
from datetime import datetime
from pathlib import Path

from fastapi import APIRouter, Depends, Request

from src.api.admin.schemas import (
    AdminHealthCheckItem,
    AdminHealthSummary,
    AdminQueueDepth,
    AdminSystemStatusResponse,
    AdminWorkerStatus,
)
from src.api.deps import get_config, get_llm_client
from src.config import Config
from src.domain.health_service import HealthService, ProductionGateConfig
from src.domain.llm_client import LLMClient
from src.infra.exceptions import QueueDataCorruptedError, QueueIOError
from src.infra.file_queue_records import load_claim, read_queue_record
from src.utils.time import utc_now

router = APIRouter(prefix="/system", tags=["admin-system"])

logger = logging.getLogger(__name__)


@router.get("/status", response_model=AdminSystemStatusResponse)
async def get_system_status(
    request: Request,
    config: Config = Depends(get_config),
    llm: LLMClient = Depends(get_llm_client),
) -> AdminSystemStatusResponse:
    now = utc_now()
    gate = ProductionGateConfig(
        is_production=config.is_production(),
        ss_env=config.ss_env,
        llm_provider=config.llm_provider,
        llm_api_key=config.llm_api_key,
        llm_base_url=config.llm_base_url,
        llm_model=config.llm_model,
        stata_cmd=config.stata_cmd,
        upload_object_store_backend=config.upload_object_store_backend,
        upload_s3_bucket=config.upload_s3_bucket,
        upload_s3_access_key_id=config.upload_s3_access_key_id,
        upload_s3_secret_access_key=config.upload_s3_secret_access_key,
    )
    health = HealthService(
        jobs_dir=config.jobs_dir,
        queue_dir=config.queue_dir,
        llm=llm,
        production_gate=gate,
    ).readiness(shutting_down=bool(getattr(request.app.state, "shutting_down", False)))

    workers = _summarize_workers(claimed_root=config.queue_dir / "claimed", now=now)
    queue = AdminQueueDepth(
        queued=_count_queue_records(config.queue_dir / "queued"),
        claimed=_count_queue_records(config.queue_dir / "claimed"),
    )
    return AdminSystemStatusResponse(
        checked_at=now.isoformat(),
        health=AdminHealthSummary(
            status="ok" if health.ok else "unhealthy",
            checks={
                name: AdminHealthCheckItem(ok=check.ok, detail=check.detail)
                for name, check in health.checks.items()
            },
        ),
        queue=queue,
        workers=workers,
    )


def _count_queue_records(root: Path) -> int:
    if not root.is_dir():
        return 0
    try:
        return sum(1 for p in root.rglob("*.json") if p.is_file())
    except OSError as e:
        logger.warning("SS_ADMIN_QUEUE_DEPTH_FAILED", extra={"root": str(root), "error": str(e)})
        return 0


def _summarize_workers(*, claimed_root: Path, now: datetime) -> list[AdminWorkerStatus]:
    if not claimed_root.is_dir():
        return []

    active_claims: dict[str, int] = defaultdict(int)
    latest_claimed_at: dict[str, str] = {}
    latest_lease_expires_at: dict[str, str] = {}

    for path in claimed_root.rglob("*.json"):
        if not path.is_file():
            continue
        try:
            record = read_queue_record(path=path)
            claim = load_claim(record=record)
        except (FileNotFoundError, QueueIOError, QueueDataCorruptedError) as e:
            logger.warning(
                "SS_ADMIN_WORKER_CLAIM_READ_FAILED",
                extra={"path": str(path), "error": str(e)},
            )
            continue

        worker_id = claim.worker_id
        if claim.lease_expires_at <= now:
            continue
        active_claims[worker_id] += 1
        claimed_at_iso = claim.claimed_at.isoformat()
        lease_iso = claim.lease_expires_at.isoformat()
        if claimed_at_iso > latest_claimed_at.get(worker_id, ""):
            latest_claimed_at[worker_id] = claimed_at_iso
        if lease_iso > latest_lease_expires_at.get(worker_id, ""):
            latest_lease_expires_at[worker_id] = lease_iso

    items = [
        AdminWorkerStatus(
            worker_id=worker_id,
            active_claims=count,
            latest_claimed_at=latest_claimed_at.get(worker_id),
            latest_lease_expires_at=latest_lease_expires_at.get(worker_id),
        )
        for worker_id, count in active_claims.items()
    ]
    items.sort(key=lambda item: item.worker_id)
    return items
