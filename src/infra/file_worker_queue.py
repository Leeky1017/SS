from __future__ import annotations

import json
import logging
import uuid
from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path
from typing import Callable

from src.domain.worker_queue import QueueClaim, WorkerQueue
from src.infra.exceptions import QueueDataCorruptedError, QueueIOError
from src.infra.file_queue_records import (
    assert_safe_segment,
    atomic_write_json,
    build_claim_fields,
    load_claim,
    read_queue_record,
)
from src.utils.tenancy import DEFAULT_TENANT_ID, is_safe_tenant_id
from src.utils.time import utc_now

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class FileWorkerQueue(WorkerQueue):
    queue_dir: Path
    lease_ttl_seconds: int = 60
    clock: Callable[[], datetime] = utc_now

    def enqueue(
        self,
        job_id: str,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        traceparent: str | None = None,
    ) -> None:
        self._ensure_dirs()
        path = self._queued_path(tenant_id=tenant_id, job_id=job_id)
        path.parent.mkdir(parents=True, exist_ok=True)
        payload: dict[str, object] = {
            "tenant_id": tenant_id,
            "job_id": job_id,
            "enqueued_at": self.clock().isoformat(),
        }
        if traceparent is not None:
            payload["traceparent"] = traceparent
        try:
            with path.open("x", encoding="utf-8") as f:
                json.dump(payload, f, ensure_ascii=False, indent=2, sort_keys=True)
        except FileExistsError:
            logger.info(
                "SS_QUEUE_ENQUEUE_IDEMPOTENT",
                extra={"tenant_id": tenant_id, "job_id": job_id, "path": str(path)},
            )
            return
        except OSError as e:
            logger.warning(
                "SS_QUEUE_ENQUEUE_FAILED",
                extra={
                    "tenant_id": tenant_id,
                    "job_id": job_id,
                    "path": str(path),
                    "error": str(e),
                },
            )
            raise QueueIOError(operation="enqueue", path=str(path)) from e

    def claim(self, *, worker_id: str) -> QueueClaim | None:
        self._ensure_dirs()
        now = self.clock()
        claim = self._claim_from_queued(worker_id=worker_id, now=now)
        if claim is not None:
            return claim
        return self._claim_from_expired(worker_id=worker_id, now=now)

    def ack(self, *, claim: QueueClaim) -> None:
        path = self._claimed_path(
            tenant_id=claim.tenant_id,
            job_id=claim.job_id,
            claim_id=claim.claim_id,
        )
        try:
            path.unlink(missing_ok=True)
        except OSError as e:
            logger.warning(
                "SS_QUEUE_ACK_FAILED",
                extra={
                    "tenant_id": claim.tenant_id,
                    "job_id": claim.job_id,
                    "claim_id": claim.claim_id,
                    "path": str(path),
                },
            )
            raise QueueIOError(operation="ack", path=str(path)) from e

    def release(self, *, claim: QueueClaim) -> None:
        source = self._claimed_path(
            tenant_id=claim.tenant_id,
            job_id=claim.job_id,
            claim_id=claim.claim_id,
        )
        target = self._queued_path(tenant_id=claim.tenant_id, job_id=claim.job_id)
        target.parent.mkdir(parents=True, exist_ok=True)
        if not source.exists():
            return
        if target.exists():
            try:
                source.unlink(missing_ok=True)
            except OSError as e:
                logger.warning(
                    "SS_QUEUE_RELEASE_CLEANUP_FAILED",
                    extra={
                        "tenant_id": claim.tenant_id,
                        "job_id": claim.job_id,
                        "path": str(source),
                    },
                )
                raise QueueIOError(operation="release_cleanup", path=str(source)) from e
            return
        try:
            source.rename(target)
        except FileNotFoundError:
            return
        except OSError as e:
            logger.warning(
                "SS_QUEUE_RELEASE_FAILED",
                extra={
                    "tenant_id": claim.tenant_id,
                    "job_id": claim.job_id,
                    "src": str(source),
                    "dst": str(target),
                },
            )
            raise QueueIOError(operation="release", path=str(source)) from e

    def _ensure_dirs(self) -> None:
        self.queue_dir.mkdir(parents=True, exist_ok=True)
        self._queued_root_dir().mkdir(parents=True, exist_ok=True)
        self._claimed_root_dir().mkdir(parents=True, exist_ok=True)

    def _queued_root_dir(self) -> Path:
        return self.queue_dir / "queued"

    def _claimed_root_dir(self) -> Path:
        return self.queue_dir / "claimed"

    def _tenant_dir(self, *, root: Path, tenant_id: str) -> Path:
        if tenant_id == DEFAULT_TENANT_ID:
            return root
        if not is_safe_tenant_id(tenant_id):
            raise ValueError("tenant_id must be a safe path segment")
        return root / tenant_id

    def _queued_dir(self, *, tenant_id: str) -> Path:
        return self._tenant_dir(root=self._queued_root_dir(), tenant_id=tenant_id)

    def _claimed_dir(self, *, tenant_id: str) -> Path:
        return self._tenant_dir(root=self._claimed_root_dir(), tenant_id=tenant_id)

    def _queued_path(self, *, tenant_id: str, job_id: str) -> Path:
        assert_safe_segment(job_id)
        return self._queued_dir(tenant_id=tenant_id) / f"{job_id}.json"

    def _claimed_path(self, *, tenant_id: str, job_id: str, claim_id: str) -> Path:
        assert_safe_segment(job_id)
        assert_safe_segment(claim_id)
        return self._claimed_dir(tenant_id=tenant_id) / f"{job_id}__{claim_id}.json"

    def _claim_from_queued(self, *, worker_id: str, now: datetime) -> QueueClaim | None:
        for tenant_id, queued_path in self._iter_queued_records():
            job_id = queued_path.stem
            try:
                claim = self._claim_file(
                    source=queued_path,
                    tenant_id=tenant_id,
                    job_id=job_id,
                    worker_id=worker_id,
                    now=now,
                )
            except FileNotFoundError:
                continue
            if claim is not None:
                return claim
        return None

    def _claim_from_expired(self, *, worker_id: str, now: datetime) -> QueueClaim | None:
        for tenant_id, claim_path in self._iter_claimed_records():
            try:
                record = read_queue_record(path=claim_path)
            except FileNotFoundError:
                continue
            lease_expires_at = record.get("lease_expires_at", "")
            if not isinstance(lease_expires_at, str):
                logger.warning("SS_QUEUE_CLAIM_EXPIRES_AT_INVALID", extra={"path": str(claim_path)})
                raise QueueDataCorruptedError(path=str(claim_path))
            try:
                expires = datetime.fromisoformat(lease_expires_at)
            except (TypeError, ValueError):
                logger.warning("SS_QUEUE_CLAIM_EXPIRES_AT_INVALID", extra={"path": str(claim_path)})
                raise QueueDataCorruptedError(path=str(claim_path))
            if now < expires:
                continue
            job_id = str(record.get("job_id", ""))
            if job_id == "":
                raise QueueDataCorruptedError(path=str(claim_path))
            try:
                claim = self._claim_file(
                    source=claim_path,
                    tenant_id=tenant_id,
                    job_id=job_id,
                    worker_id=worker_id,
                    now=now,
                )
            except FileNotFoundError:
                continue
            if claim is not None:
                return claim
        return None

    def _claim_file(
        self,
        *,
        source: Path,
        tenant_id: str,
        job_id: str,
        worker_id: str,
        now: datetime,
    ) -> QueueClaim | None:
        claim_id = uuid.uuid4().hex
        target = self._claimed_path(tenant_id=tenant_id, job_id=job_id, claim_id=claim_id)
        tmp_target = target.with_suffix(".tmp")
        tmp_target.parent.mkdir(parents=True, exist_ok=True)
        try:
            source.rename(tmp_target)
        except FileNotFoundError:
            raise
        except OSError as e:
            logger.warning(
                "SS_QUEUE_CLAIM_RENAME_FAILED",
                extra={"job_id": job_id, "src": str(source), "dst": str(tmp_target)},
            )
            raise QueueIOError(operation="claim_rename", path=str(source)) from e

        record = read_queue_record(path=tmp_target)
        record["tenant_id"] = tenant_id
        record["job_id"] = job_id
        record.update(
            build_claim_fields(
                worker_id=worker_id,
                claim_id=claim_id,
                now=now,
                ttl=self._ttl(),
            )
        )
        try:
            atomic_write_json(path=tmp_target, payload=record)
        except OSError as e:
            logger.warning(
                "SS_QUEUE_CLAIM_WRITE_FAILED",
                extra={"job_id": job_id, "path": str(tmp_target), "error": str(e)},
            )
            self._try_requeue(tenant_id=tenant_id, job_id=job_id, source=tmp_target)
            raise QueueIOError(operation="claim_write", path=str(tmp_target)) from e

        try:
            tmp_target.rename(target)
        except OSError as e:
            logger.warning(
                "SS_QUEUE_CLAIM_FINALIZE_FAILED",
                extra={"job_id": job_id, "src": str(tmp_target), "dst": str(target)},
            )
            self._try_requeue(tenant_id=tenant_id, job_id=job_id, source=tmp_target)
            raise QueueIOError(operation="claim_finalize", path=str(tmp_target)) from e

        claim = load_claim(record=record)
        logger.info(
            "SS_QUEUE_CLAIMED",
            extra={
                "tenant_id": claim.tenant_id,
                "job_id": claim.job_id,
                "claim_id": claim.claim_id,
                "worker_id": claim.worker_id,
            },
        )
        return claim

    def _ttl(self) -> timedelta:
        try:
            ttl = int(self.lease_ttl_seconds)
        except (TypeError, ValueError):
            ttl = 60
        if ttl <= 0:
            ttl = 60
        return timedelta(seconds=ttl)

    def _try_requeue(self, *, tenant_id: str, job_id: str, source: Path) -> None:
        target = self._queued_path(tenant_id=tenant_id, job_id=job_id)
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists():
            return
        try:
            source.rename(target)
        except OSError:
            logger.warning(
                "SS_QUEUE_REQUEUE_FAILED",
                extra={
                    "tenant_id": tenant_id,
                    "job_id": job_id,
                    "src": str(source),
                    "dst": str(target),
                },
            )

    def _iter_queued_records(self) -> list[tuple[str, Path]]:
        root = self._queued_root_dir()
        records: list[tuple[str, Path]] = []
        if root.exists():
            for path in sorted(root.glob("*.json")):
                records.append((DEFAULT_TENANT_ID, path))
            for tenant_dir in sorted(p for p in root.iterdir() if p.is_dir()):
                tenant_id = tenant_dir.name
                if not is_safe_tenant_id(tenant_id):
                    logger.warning(
                        "SS_TENANT_ID_UNSAFE",
                        extra={"tenant_id": tenant_id, "path": str(tenant_dir)},
                    )
                    continue
                for path in sorted(tenant_dir.glob("*.json")):
                    records.append((tenant_id, path))
        return records

    def _iter_claimed_records(self) -> list[tuple[str, Path]]:
        root = self._claimed_root_dir()
        records: list[tuple[str, Path]] = []
        if root.exists():
            for path in sorted(root.glob("*.json")):
                records.append((DEFAULT_TENANT_ID, path))
            for tenant_dir in sorted(p for p in root.iterdir() if p.is_dir()):
                tenant_id = tenant_dir.name
                if not is_safe_tenant_id(tenant_id):
                    logger.warning(
                        "SS_TENANT_ID_UNSAFE",
                        extra={"tenant_id": tenant_id, "path": str(tenant_dir)},
                    )
                    continue
                for path in sorted(tenant_dir.glob("*.json")):
                    records.append((tenant_id, path))
        return records
