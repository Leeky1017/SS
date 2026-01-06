from __future__ import annotations

import logging
from dataclasses import dataclass

from src.domain.job_service import JobScheduler
from src.domain.models import Job
from src.domain.worker_queue import WorkerQueue

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class QueueJobScheduler(JobScheduler):
    queue: WorkerQueue

    def schedule(self, *, job: Job) -> None:
        self.queue.enqueue(job_id=job.job_id)
        logger.info("SS_JOB_ENQUEUED", extra={"job_id": job.job_id})

