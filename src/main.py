from __future__ import annotations

from typing import cast

from fastapi import FastAPI
from fastapi.responses import JSONResponse
from starlette.requests import Request
from starlette.responses import Response

from src.api.routes import api_router
from src.config import load_config
from src.infra.exceptions import SSError
from src.infra.logging_config import build_logging_config


def create_app() -> FastAPI:
    config = load_config()
    app = FastAPI(title="SS", version="0.0.0")
    app.state.config = config
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
