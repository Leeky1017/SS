from __future__ import annotations

from fastapi import APIRouter, Depends, Request
from fastapi.responses import JSONResponse

from src.api.deps import get_config, get_llm_client
from src.api.schemas import HealthCheck, HealthResponse
from src.config import Config
from src.domain.health_service import HealthService, ProductionGateConfig
from src.domain.llm_client import LLMClient
from src.utils.time import utc_now

router = APIRouter()


@router.get("/health/live", response_model=HealthResponse)
async def health_live() -> HealthResponse:
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
async def health_ready(
    request: Request,
    config: Config = Depends(get_config),
    llm: LLMClient = Depends(get_llm_client),
) -> HealthResponse | JSONResponse:
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
    service = HealthService(
        jobs_dir=config.jobs_dir,
        queue_dir=config.queue_dir,
        llm=llm,
        production_gate=gate,
    )
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
