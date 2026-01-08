from __future__ import annotations

from starlette.requests import Request

from src.domain.audit import AuditContext


async def get_audit_context(request: Request) -> AuditContext:
    actor_id = request.headers.get("x-ss-actor-id")
    if actor_id is not None and actor_id.strip() == "":
        actor_id = None

    request_id = getattr(request.state, "request_id", None)
    client = request.client
    ip = None if client is None else client.host
    user_agent = request.headers.get("user-agent")

    return AuditContext.user(
        actor_id=actor_id,
        request_id=request_id,
        ip=ip,
        user_agent=user_agent,
        source="api",
    )
