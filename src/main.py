from __future__ import annotations

import logging
import os
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import cast

from fastapi import FastAPI
from fastapi.responses import JSONResponse
from starlette.middleware.base import RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import Response

from src.api.routes import api_router
from src.config import load_config
from src.infra.exceptions import ServiceShuttingDownError, SSError
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

    @app.middleware("http")
    async def reject_during_shutdown(
        request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        if getattr(request.app.state, "shutting_down", False):
            return _handle_ss_error(request, ServiceShuttingDownError())
        return await call_next(request)

    app.include_router(api_router)
    app.add_exception_handler(SSError, _handle_ss_error)
    return app


def _handle_ss_error(_request: Request, exc: Exception) -> Response:
    ss_error = cast(SSError, exc)
    return JSONResponse(status_code=ss_error.status_code, content=ss_error.to_dict())


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
