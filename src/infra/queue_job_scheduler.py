from __future__ import annotations

import logging
from dataclasses import dataclass

from opentelemetry.trace import get_tracer

from src.domain.job_support import JobScheduler
from src.domain.models import Job
from src.domain.worker_queue import WorkerQueue
from src.infra.tracing import (
    build_traceparent,
    context_from_traceparent,
    inject_current_context,
    new_span_id_hex,
)

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class QueueJobScheduler(JobScheduler):
    queue: WorkerQueue

    def schedule(self, *, job: Job) -> None:
        traceparent = None
        if job.trace_id is not None:
            synthetic_traceparent = build_traceparent(
                trace_id=job.trace_id,
                span_id=new_span_id_hex(),
                sampled=True,
            )
            context = context_from_traceparent(synthetic_traceparent)
            tracer = get_tracer(__name__)
            with tracer.start_as_current_span("ss.job.enqueue", context=context) as span:
                span.set_attribute("ss.job_id", job.job_id)
                carrier: dict[str, str] = {}
                inject_current_context(carrier=carrier)
                traceparent = carrier.get("traceparent", synthetic_traceparent)
        self.queue.enqueue(tenant_id=job.tenant_id, job_id=job.job_id, traceparent=traceparent)
        logger.info("SS_JOB_ENQUEUED", extra={"tenant_id": job.tenant_id, "job_id": job.job_id})
