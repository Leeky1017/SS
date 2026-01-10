from __future__ import annotations

from pathlib import Path

import pytest

from src.infra.object_store_exceptions import ObjectStoreConfigurationError
from src.main import create_app
from tests.asgi_client import asgi_client


@pytest.mark.anyio
async def test_startup_in_production_without_s3_config_raises_configuration_error(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setenv("SS_ENV", "production")
    monkeypatch.setenv("SS_JOBS_DIR", str(tmp_path / "jobs"))
    monkeypatch.setenv("SS_QUEUE_DIR", str(tmp_path / "queue"))
    monkeypatch.delenv("SS_UPLOAD_S3_BUCKET", raising=False)
    monkeypatch.delenv("SS_UPLOAD_S3_ACCESS_KEY_ID", raising=False)
    monkeypatch.delenv("SS_UPLOAD_S3_SECRET_ACCESS_KEY", raising=False)

    app = create_app()

    with pytest.raises(ObjectStoreConfigurationError) as excinfo:
        async with asgi_client(app=app):
            pass

    assert excinfo.value.error_code == "OBJECT_STORE_CONFIG_INVALID"
    assert "missing SS_UPLOAD_S3_BUCKET" in excinfo.value.message

