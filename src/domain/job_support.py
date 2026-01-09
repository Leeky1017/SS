from __future__ import annotations

import secrets
from dataclasses import dataclass

from src.domain.audit import AuditContext, AuditEvent, AuditLogger
from src.domain.models import Job
from src.utils.json_types import JsonObject


def new_trace_id() -> str:
    return secrets.token_hex(16)


class JobScheduler:
    def schedule(self, *, job: Job) -> None:
        raise NotImplementedError


@dataclass(frozen=True)
class NoopJobScheduler(JobScheduler):
    """Placeholder scheduler: records schedule intent only."""

    def schedule(self, *, job: Job) -> None:
        return None


def emit_job_audit(
    *,
    audit: AuditLogger,
    audit_context: AuditContext,
    action: str,
    tenant_id: str,
    job_id: str,
    result: str,
    changes: JsonObject | None = None,
    metadata: JsonObject | None = None,
) -> None:
    final_meta: JsonObject = {"tenant_id": tenant_id}
    if metadata is not None:
        final_meta.update(metadata)
    event = AuditEvent(
        action=action,
        result=result,
        resource_type="job",
        resource_id=job_id,
        job_id=job_id,
        context=audit_context,
        changes=changes,
        metadata=final_meta,
    )
    audit.emit(event=event)

