from __future__ import annotations

import logging
import secrets
from pathlib import Path

from src.domain.models import (
    JOB_SCHEMA_VERSION_CURRENT,
    JOB_SCHEMA_VERSION_V1,
    JOB_SCHEMA_VERSION_V2,
    JOB_SCHEMA_VERSION_V3,
    SUPPORTED_JOB_SCHEMA_VERSIONS,
)
from src.infra.exceptions import JobDataCorruptedError
from src.utils.json_types import JsonObject

logger = logging.getLogger("src.infra.job_store")


def assert_supported_schema_version(*, job_id: str, path: Path, payload: JsonObject) -> None:
    schema_version = payload.get("schema_version")
    if schema_version in SUPPORTED_JOB_SCHEMA_VERSIONS:
        return
    logger.warning(
        "SS_JOB_JSON_SCHEMA_VERSION_UNSUPPORTED",
        extra={
            "job_id": job_id,
            "path": str(path),
            "schema_version": schema_version,
            "supported_versions": list(SUPPORTED_JOB_SCHEMA_VERSIONS),
        },
    )
    raise JobDataCorruptedError(job_id=job_id)


def migrate_payload_to_current(*, job_id: str, path: Path, payload: JsonObject) -> JsonObject:
    schema_version = payload.get("schema_version")
    migrated = payload
    if schema_version == JOB_SCHEMA_VERSION_V1:
        migrated = _migrate_v1_to_v2(job_id=job_id, path=path, payload=migrated)
        schema_version = migrated.get("schema_version")
    if schema_version == JOB_SCHEMA_VERSION_V2:
        migrated = _migrate_v2_to_v3(job_id=job_id, path=path, payload=migrated)
        schema_version = migrated.get("schema_version")
    if schema_version == JOB_SCHEMA_VERSION_CURRENT:
        return _ensure_trace_id(job_id=job_id, path=path, payload=migrated)
    logger.warning(
        "SS_JOB_JSON_SCHEMA_MIGRATION_UNDEFINED",
        extra={"job_id": job_id, "path": str(path), "schema_version": schema_version},
    )
    raise JobDataCorruptedError(job_id=job_id)


def _ensure_trace_id(*, job_id: str, path: Path, payload: JsonObject) -> JsonObject:
    trace_id = payload.get("trace_id")
    if isinstance(trace_id, str) and trace_id.strip() != "":
        return payload
    migrated: JsonObject = dict(payload)
    migrated["trace_id"] = secrets.token_hex(16)
    logger.info("SS_JOB_TRACE_ID_BACKFILLED", extra={"job_id": job_id, "path": str(path)})
    return migrated


def _migrate_v1_to_v2(*, job_id: str, path: Path, payload: JsonObject) -> JsonObject:
    migrated: JsonObject = dict(payload)
    for key in ("runs", "artifacts_index"):
        if key not in migrated:
            migrated[key] = []
            continue
        if not isinstance(migrated[key], list):
            logger.warning(
                "SS_JOB_JSON_CORRUPTED",
                extra={"job_id": job_id, "path": str(path), "reason": f"{key}_not_list"},
            )
            raise JobDataCorruptedError(job_id=job_id)
    migrated["schema_version"] = JOB_SCHEMA_VERSION_V2
    logger.info(
        "SS_JOB_JSON_SCHEMA_MIGRATED",
        extra={
            "job_id": job_id,
            "from_version": JOB_SCHEMA_VERSION_V1,
            "to_version": JOB_SCHEMA_VERSION_V2,
        },
    )
    return migrated


def _migrate_v2_to_v3(*, job_id: str, path: Path, payload: JsonObject) -> JsonObject:
    migrated: JsonObject = dict(payload)
    version = migrated.get("version")
    if version is None:
        migrated["version"] = 1
    elif not isinstance(version, int) or version < 1:
        logger.warning(
            "SS_JOB_JSON_CORRUPTED",
            extra={"job_id": job_id, "path": str(path), "reason": "version_invalid"},
        )
        raise JobDataCorruptedError(job_id=job_id)
    migrated["schema_version"] = JOB_SCHEMA_VERSION_V3
    logger.info(
        "SS_JOB_JSON_SCHEMA_MIGRATED",
        extra={
            "job_id": job_id,
            "from_version": JOB_SCHEMA_VERSION_V2,
            "to_version": JOB_SCHEMA_VERSION_V3,
        },
    )
    return migrated
