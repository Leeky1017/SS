from __future__ import annotations

import logging
import os
import time
import uuid
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from pathlib import Path
from typing import cast

from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from starlette.middleware.base import RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import Response
from starlette.types import Receive, Scope, Send

from src.api.routes import admin_api_router, api_v1_router, ops_router
from src.api.versioning import add_legacy_deprecation_headers, is_legacy_unversioned_path
from src.config import Config, load_config
from src.infra.exceptions import OutOfMemoryError, ServiceShuttingDownError, SSError
from src.infra.logging_config import build_logging_config
from src.infra.object_store_exceptions import ObjectStoreConfigurationError
from src.infra.object_store_factory import build_object_store
from src.infra.structured_errors import StructuredSSError
from src.infra.tracing import configure_tracing

logger = logging.getLogger(__name__)


class _FrontendStaticFiles(StaticFiles):
    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope.get("type") == "http":
            method = str(scope.get("method", "")).upper()
            if method not in {"GET", "HEAD"}:
                await Response(status_code=404)(scope, receive, send)
                return
        await super().__call__(scope, receive, send)


def _validate_production_upload_object_store(*, config: Config) -> None:
    if not config.is_production():
        return
    try:
        build_object_store(config=config)
    except ObjectStoreConfigurationError as exc:
        logger.error(
            "SS_PRODUCTION_GATE_UPLOAD_OBJECT_STORE_INVALID",
            extra={"error_code": exc.error_code, "error_message": exc.message},
        )
        raise


def _clear_dependency_caches() -> None:
    from src.api import deps

    deps.clear_dependency_caches()


def _frontend_dist_dir() -> Path:
    return (Path(__file__).resolve().parents[1] / "frontend" / "dist").resolve()


def _frontend_index_html() -> Path | None:
    dist_dir = _frontend_dist_dir()
    index_path = dist_dir / "index.html"
    return index_path if index_path.is_file() else None


def _mount_frontend_if_present(*, app: FastAPI) -> None:
    dist_dir = _frontend_dist_dir()
    if not dist_dir.is_dir():
        logger.info("SS_FRONTEND_DIST_NOT_FOUND", extra={"path": str(dist_dir)})
        return
    app.mount("/", _FrontendStaticFiles(directory=str(dist_dir), html=True), name="frontend")
    logger.info("SS_FRONTEND_DIST_MOUNTED", extra={"path": str(dist_dir)})


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    app.state.shutting_down = False
    config = app.state.config
    configure_tracing(config=config, component="api")
    logger.info("SS_API_STARTUP", extra={"pid": os.getpid(), "log_level": config.log_level})
    _validate_production_upload_object_store(config=config)
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

    from src.api.deps import get_metrics_sync

    metrics = get_metrics_sync()

    @app.middleware("http")
    async def reject_during_shutdown(
        request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        request_id = request.headers.get("x-ss-request-id")
        if request_id is None:
            request_id = request.headers.get("x-request-id")
        if request_id is None or request_id.strip() == "":
            request_id = uuid.uuid4().hex
        request.state.request_id = request_id

        started = time.perf_counter()
        if getattr(request.app.state, "shutting_down", False):
            response = await _handle_ss_error(request, ServiceShuttingDownError())
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
        response.headers["X-SS-Request-Id"] = request_id
        return response

    app.include_router(api_v1_router)
    app.include_router(admin_api_router)
    app.include_router(ops_router, include_in_schema=False)
    app.add_exception_handler(RequestValidationError, _handle_request_validation_error)
    app.add_exception_handler(SSError, _handle_ss_error)
    app.add_exception_handler(MemoryError, _handle_oom_error)

    @app.get("/admin", include_in_schema=False)
    async def _redirect_admin() -> Response:
        return Response(status_code=307, headers={"Location": "/admin/"})

    @app.get("/admin/", include_in_schema=False)
    async def _admin_index() -> Response:
        index_html = _frontend_index_html()
        if index_html is None:
            return Response(status_code=404)
        return FileResponse(path=str(index_html), media_type="text/html")

    _mount_frontend_if_present(app=app)
    return app


async def _handle_ss_error(_request: Request, exc: Exception) -> Response:
    ss_error = cast(SSError, exc)
    payload: dict[str, object] = dict(ss_error.to_dict())
    if isinstance(ss_error, StructuredSSError):
        payload.update(ss_error.details)
    return JSONResponse(status_code=ss_error.status_code, content=payload)


async def _handle_request_validation_error(request: Request, exc: Exception) -> Response:
    validation_error = cast(RequestValidationError, exc)
    request_id = getattr(request.state, "request_id", None)
    logger.info(
        "SS_REQUEST_VALIDATION_FAILED",
        extra={
            "request_id": request_id,
            "path": request.url.path,
            "errors_count": len(validation_error.errors()),
        },
    )
    return JSONResponse(
        status_code=400,
        content=SSError(error_code="INPUT_VALIDATION_FAILED", message="input is invalid").to_dict(),
    )


async def _handle_oom_error(request: Request, _exc: Exception) -> Response:
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
