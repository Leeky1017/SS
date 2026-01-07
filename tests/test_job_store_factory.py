from __future__ import annotations

import pytest

from src.config import load_config
from src.infra.exceptions import JobStoreBackendUnsupportedError
from src.infra.job_store import JobStore as FileJobStore
from src.infra.job_store_factory import build_job_store


def test_build_job_store_with_default_config_returns_file_job_store() -> None:
    config = load_config(env={})

    store = build_job_store(config=config)

    assert isinstance(store, FileJobStore)


def test_build_job_store_with_unsupported_backend_raises_unsupported_error() -> None:
    config = load_config(env={"SS_JOB_STORE_BACKEND": "redis"})

    with pytest.raises(JobStoreBackendUnsupportedError) as exc:
        build_job_store(config=config)

    assert exc.value.error_code == "JOB_STORE_BACKEND_UNSUPPORTED"
