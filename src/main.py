from __future__ import annotations

import logging
import os
import time
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import cast

from fastapi import FastAPI
from fastapi.responses import JSONResponse
from starlette.middleware.base import RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import Response

from src.api.routes import api_router, api_v1_router
from src.api.versioning import add_legacy_deprecation_headers, is_legacy_unversioned_path
from src.config import load_config
from src.infra.exceptions import OutOfMemoryError, ServiceShuttingDownError, SSError
from src.infra.logging_config import build_logging_config

logger = logging.getLogger(__name__)


def _clear_dependency_caches() -> None:
    from src.api import deps

    deps.get_config.cache_clear()
    deps.get_job_store.cache_clear()
    deps.get_worker_queue.cache_clear()
    deps.get_llm_client.cache_clear()
    deps.get_job_state_machine.cache_clear()
    deps.get_job_idempotency.cache_clear()
    deps.get_metrics.cache_clear()
    deps.get_artifacts_service.cache_clear()


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    app.state.shutting_down = False
    config = app.state.config
    logger.info("SS_API_STARTUP", extra={"pid": os.getpid(), "log_level": config.log_level})
    try:
        yield
    finally:
        app.state.shutting_down = True
        logger.info("SS_API_SHUTDOWN_INITIATED", extra={"pid": os.getpid()})
        _clear_dependency_caches()
        logger.info("SS_API_SHUTDOWN_COMPLETE", extra={"pid": os.getpid()})


def create_app() -> FastAPI:
    config = load_config()
    app = FastAPI(title="SS", version="0.0.0", lifespan=lifespan)
    app.state.config = config
    app.state.shutting_down = False
    from src.api.deps import get_metrics

    metrics = get_metrics()

    @app.middleware("http")
    async def reject_during_shutdown(
        request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        started = time.perf_counter()
        if getattr(request.app.state, "shutting_down", False):
            response = _handle_ss_error(request, ServiceShuttingDownError())
        else:
            response = await call_next(request)

        duration = time.perf_counter() - started
        route_path = getattr(request.scope.get("route"), "path", None)
        route = route_path if isinstance(route_path, str) else "unmatched"
        if request.url.path != "/metrics":
            metrics.observe_http_request(
                method=request.method,
                route=str(route),
                status_code=response.status_code,
                duration_seconds=duration,
            )

        if is_legacy_unversioned_path(request.url.path):
            add_legacy_deprecation_headers(response)
        return response

    app.include_router(api_v1_router)
    app.include_router(api_router, include_in_schema=False)
    app.add_exception_handler(SSError, _handle_ss_error)
    app.add_exception_handler(MemoryError, _handle_oom_error)
    return app


def _handle_ss_error(_request: Request, exc: Exception) -> Response:
    ss_error = cast(SSError, exc)
    return JSONResponse(status_code=ss_error.status_code, content=ss_error.to_dict())


def _handle_oom_error(request: Request, _exc: Exception) -> Response:
    logger.error("SS_RESOURCE_OOM", extra={"path": request.url.path})
    return JSONResponse(status_code=503, content=OutOfMemoryError().to_dict())


app = create_app()


def main() -> None:
    import uvicorn

    config = app.state.config
    log_config = build_logging_config(log_level=config.log_level)
    uvicorn.run(
        "src.main:app",
        host="0.0.0.0",
        port=8000,
        log_level=str(log_config["root"]["level"]).lower(),
        log_config=log_config,
    )


if __name__ == "__main__":
    main()
