from __future__ import annotations

from fastapi import APIRouter, Depends, Request
from fastapi.responses import JSONResponse

from src.api.deps import get_config, get_llm_client
from src.api.schemas import HealthCheck, HealthResponse
from src.config import Config
from src.domain.health_service import HealthService
from src.domain.llm_client import LLMClient
from src.utils.time import utc_now

router = APIRouter()


@router.get("/health/live", response_model=HealthResponse)
def health_live() -> HealthResponse:
    return HealthResponse(
        status="ok",
        checks={"process": HealthCheck(ok=True)},
        checked_at=utc_now().isoformat(),
    )


@router.get(
    "/health/ready",
    response_model=HealthResponse,
    responses={503: {"model": HealthResponse}},
)
def health_ready(
    request: Request,
    config: Config = Depends(get_config),
    llm: LLMClient = Depends(get_llm_client),
) -> HealthResponse | JSONResponse:
    service = HealthService(jobs_dir=config.jobs_dir, queue_dir=config.queue_dir, llm=llm)
    report = service.readiness(
        shutting_down=bool(getattr(request.app.state, "shutting_down", False))
    )

    payload = HealthResponse(
        status="ok" if report.ok else "unhealthy",
        checks={
            name: HealthCheck(ok=check.ok, detail=check.detail)
            for name, check in report.checks.items()
        },
        checked_at=utc_now().isoformat(),
    )
    if report.ok:
        return payload
    return JSONResponse(status_code=503, content=payload.model_dump(mode="json"))
