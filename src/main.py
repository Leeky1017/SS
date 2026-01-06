from __future__ import annotations

from fastapi import FastAPI
from fastapi.responses import JSONResponse

from src.api.routes import api_router
from src.config import load_config
from src.infra.exceptions import SSError


def create_app() -> FastAPI:
    config = load_config()
    app = FastAPI(title="SS", version="0.0.0")
    app.state.config = config
    app.include_router(api_router)
    app.add_exception_handler(SSError, _handle_ss_error)
    return app


def _handle_ss_error(_request, exc: SSError) -> JSONResponse:
    return JSONResponse(status_code=exc.status_code, content=exc.to_dict())


app = create_app()


def main() -> None:
    import uvicorn

    uvicorn.run("src.main:app", host="0.0.0.0", port=8000, log_level="info")


if __name__ == "__main__":
    main()
