from __future__ import annotations

import logging

from src.config import Config
from src.domain.object_store import ObjectStore
from src.infra.object_store_exceptions import ObjectStoreConfigurationError
from src.infra.s3_object_store import S3ObjectStore

logger = logging.getLogger(__name__)


def build_object_store(*, config: Config) -> ObjectStore:
    backend = config.upload_object_store_backend.strip().lower()
    if backend in {"", "s3"}:
        return S3ObjectStore.from_config(config=config)
    logger.warning("SS_UPLOAD_OBJECT_STORE_BACKEND_UNSUPPORTED", extra={"backend": backend})
    raise ObjectStoreConfigurationError(
        message=f"unsupported SS_UPLOAD_OBJECT_STORE_BACKEND: {backend}",
    )
