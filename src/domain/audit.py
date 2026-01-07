from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Mapping


@dataclass(frozen=True)
class AuditActor:
    kind: str
    actor_id: str | None = None
    ip: str | None = None
    user_agent: str | None = None


@dataclass(frozen=True)
class AuditContext:
    actor: AuditActor
    request_id: str | None = None
    source: str | None = None

    @staticmethod
    def system(
        *,
        actor_id: str,
        request_id: str | None = None,
        source: str | None = None,
    ) -> "AuditContext":
        return AuditContext(
            actor=AuditActor(kind="system", actor_id=actor_id),
            request_id=request_id,
            source=source,
        )

    @staticmethod
    def user(
        *,
        actor_id: str | None,
        request_id: str | None,
        ip: str | None,
        user_agent: str | None,
        source: str | None = None,
    ) -> "AuditContext":
        return AuditContext(
            actor=AuditActor(kind="user", actor_id=actor_id, ip=ip, user_agent=user_agent),
            request_id=request_id,
            source=source,
        )


@dataclass(frozen=True)
class AuditEvent:
    action: str
    result: str
    resource_type: str
    resource_id: str
    context: AuditContext
    job_id: str | None = None
    changes: Mapping[str, Any] | None = None
    metadata: Mapping[str, Any] | None = None

    def to_log_extra(self) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "job_id": self.job_id,
            "request_id": self.context.request_id,
            "audit_action": self.action,
            "audit_result": self.result,
            "audit_resource_type": self.resource_type,
            "audit_resource_id": self.resource_id,
            "audit_actor_kind": self.context.actor.kind,
            "audit_actor_id": self.context.actor.actor_id,
            "audit_actor_ip": self.context.actor.ip,
            "audit_actor_user_agent": self.context.actor.user_agent,
            "audit_source": self.context.source,
        }
        if self.changes is not None:
            payload["audit_changes"] = dict(self.changes)
        if self.metadata is not None:
            payload["audit_metadata"] = dict(self.metadata)
        return payload


class AuditLogger:
    def emit(self, *, event: AuditEvent) -> None:
        raise NotImplementedError


@dataclass(frozen=True)
class NoopAuditLogger(AuditLogger):
    def emit(self, *, event: AuditEvent) -> None:
        return None
