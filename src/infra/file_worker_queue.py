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
from src.utils.time import utc_now

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class FileWorkerQueue(WorkerQueue):
    queue_dir: Path
    lease_ttl_seconds: int = 60
    clock: Callable[[], datetime] = utc_now

    def enqueue(self, *, job_id: str) -> None:
        self._ensure_dirs()
        path = self._queued_path(job_id=job_id)
        payload = {"job_id": job_id, "enqueued_at": self.clock().isoformat()}
        try:
            with path.open("x", encoding="utf-8") as f:
                json.dump(payload, f, ensure_ascii=False, indent=2, sort_keys=True)
        except FileExistsError:
            logger.info("SS_QUEUE_ENQUEUE_IDEMPOTENT", extra={"job_id": job_id, "path": str(path)})
            return
        except OSError as e:
            logger.warning(
                "SS_QUEUE_ENQUEUE_FAILED",
                extra={"job_id": job_id, "path": str(path), "error": str(e)},
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
        path = self._claimed_path(job_id=claim.job_id, claim_id=claim.claim_id)
        try:
            path.unlink(missing_ok=True)
        except OSError as e:
            logger.warning(
                "SS_QUEUE_ACK_FAILED",
                extra={"job_id": claim.job_id, "claim_id": claim.claim_id, "path": str(path)},
            )
            raise QueueIOError(operation="ack", path=str(path)) from e

    def release(self, *, claim: QueueClaim) -> None:
        source = self._claimed_path(job_id=claim.job_id, claim_id=claim.claim_id)
        target = self._queued_path(job_id=claim.job_id)
        if not source.exists():
            return
        if target.exists():
            try:
                source.unlink(missing_ok=True)
            except OSError as e:
                logger.warning(
                    "SS_QUEUE_RELEASE_CLEANUP_FAILED",
                    extra={"job_id": claim.job_id, "path": str(source)},
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
                extra={"job_id": claim.job_id, "src": str(source), "dst": str(target)},
            )
            raise QueueIOError(operation="release", path=str(source)) from e

    def _ensure_dirs(self) -> None:
        self.queue_dir.mkdir(parents=True, exist_ok=True)
        self._queued_dir().mkdir(parents=True, exist_ok=True)
        self._claimed_dir().mkdir(parents=True, exist_ok=True)

    def _queued_dir(self) -> Path:
        return self.queue_dir / "queued"

    def _claimed_dir(self) -> Path:
        return self.queue_dir / "claimed"

    def _queued_path(self, *, job_id: str) -> Path:
        assert_safe_segment(job_id)
        return self._queued_dir() / f"{job_id}.json"

    def _claimed_path(self, *, job_id: str, claim_id: str) -> Path:
        assert_safe_segment(job_id)
        assert_safe_segment(claim_id)
        return self._claimed_dir() / f"{job_id}__{claim_id}.json"

    def _claim_from_queued(self, *, worker_id: str, now: datetime) -> QueueClaim | None:
        for queued_path in sorted(self._queued_dir().glob("*.json")):
            job_id = queued_path.stem
            try:
                claim = self._claim_file(
                    source=queued_path,
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
        for claim_path in sorted(self._claimed_dir().glob("*.json")):
            try:
                record = read_queue_record(path=claim_path)
            except FileNotFoundError:
                continue
            lease_expires_at = record.get("lease_expires_at", "")
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
        job_id: str,
        worker_id: str,
        now: datetime,
    ) -> QueueClaim | None:
        claim_id = uuid.uuid4().hex
        target = self._claimed_path(job_id=job_id, claim_id=claim_id)
        tmp_target = target.with_suffix(".tmp")
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
            self._try_requeue(job_id=job_id, source=tmp_target)
            raise QueueIOError(operation="claim_write", path=str(tmp_target)) from e

        try:
            tmp_target.rename(target)
        except OSError as e:
            logger.warning(
                "SS_QUEUE_CLAIM_FINALIZE_FAILED",
                extra={"job_id": job_id, "src": str(tmp_target), "dst": str(target)},
            )
            self._try_requeue(job_id=job_id, source=tmp_target)
            raise QueueIOError(operation="claim_finalize", path=str(tmp_target)) from e

        claim = load_claim(record=record)
        logger.info(
            "SS_QUEUE_CLAIMED",
            extra={
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

    def _try_requeue(self, *, job_id: str, source: Path) -> None:
        target = self._queued_path(job_id=job_id)
        if target.exists():
            return
        try:
            source.rename(target)
        except OSError:
            logger.warning(
                "SS_QUEUE_REQUEUE_FAILED",
                extra={"job_id": job_id, "src": str(source), "dst": str(target)},
            )
