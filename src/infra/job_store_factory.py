from __future__ import annotations

import logging

from src.config import Config
from src.domain.job_store import JobStore
from src.infra.exceptions import JobStoreBackendUnsupportedError
from src.infra.job_store import JobStore as FileJobStore

logger = logging.getLogger(__name__)


def build_job_store(*, config: Config) -> JobStore:
    backend = config.job_store_backend
    if backend == "file":
        return FileJobStore(jobs_dir=config.jobs_dir)
    logger.warning("SS_JOB_STORE_BACKEND_UNSUPPORTED", extra={"backend": backend})
    raise JobStoreBackendUnsupportedError(backend=backend)

