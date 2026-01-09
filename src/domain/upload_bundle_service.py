from __future__ import annotations

import json
import uuid
from collections.abc import Sequence
from dataclasses import dataclass
from typing import Any, cast

from src.domain.inputs_manifest import (
    ROLE_AUXILIARY_DATA,
    ROLE_PRIMARY_DATASET,
    ROLE_SECONDARY_DATASET,
    format_from_filename,
)
from src.domain.job_workspace_store import JobWorkspaceStore
from src.infra.input_exceptions import (
    InputFilenameUnsafeError,
    InputPrimaryDatasetMissingError,
    InputPrimaryDatasetMultipleError,
    InputRoleInvalidError,
)
from src.infra.upload_bundle_exceptions import (
    BundleCorruptedError,
    BundleFilesLimitExceededError,
    BundleNotFoundError,
)
from src.utils.job_workspace import is_safe_path_segment
from src.utils.json_types import JsonObject
from src.utils.tenancy import DEFAULT_TENANT_ID

BUNDLE_REL_PATH = "inputs/bundle.json"

ROLE_OTHER = "other"
ALLOWED_BUNDLE_ROLES = {
    ROLE_PRIMARY_DATASET,
    ROLE_SECONDARY_DATASET,
    ROLE_AUXILIARY_DATA,
    ROLE_OTHER,
}


@dataclass(frozen=True)
class BundleFileDeclaration:
    filename: str
    size_bytes: int
    role: str
    mime_type: str | None


@dataclass(frozen=True)
class BundleFile(BundleFileDeclaration):
    file_id: str


@dataclass(frozen=True)
class Bundle:
    bundle_id: str
    job_id: str
    files: tuple[BundleFile, ...]


def _safe_declared_filename(filename: str) -> str:
    candidate = filename.strip()
    if candidate == "" or not is_safe_path_segment(candidate):
        raise InputFilenameUnsafeError(filename=filename)
    return candidate


def _validate_role(role: str) -> str:
    candidate = role.strip()
    if candidate in ALLOWED_BUNDLE_ROLES:
        return candidate
    raise InputRoleInvalidError(role=role)


def _mime_or_none(mime_type: str | None) -> str | None:
    if mime_type is None:
        return None
    candidate = mime_type.strip()
    if candidate == "":
        return None
    return candidate


class UploadBundleService:
    def __init__(self, *, workspace: JobWorkspaceStore, max_bundle_files: int):
        self._workspace = workspace
        self._max_bundle_files = max_bundle_files

    def _assert_file_limit(self, *, file_count: int) -> None:
        if file_count <= self._max_bundle_files:
            return
        raise BundleFilesLimitExceededError(
            max_files=self._max_bundle_files,
            actual_files=file_count,
        )

    def _normalize_files(
        self,
        *,
        files: Sequence[BundleFileDeclaration],
    ) -> tuple[tuple[BundleFile, ...], int]:
        normalized: list[BundleFile] = []
        primary_count = 0
        for item in files:
            safe_name = _safe_declared_filename(item.filename)
            _ = format_from_filename(safe_name)
            role = _validate_role(item.role)
            if role == ROLE_PRIMARY_DATASET:
                primary_count += 1
            normalized.append(
                BundleFile(
                    file_id=f"file_{uuid.uuid4().hex}",
                    filename=safe_name,
                    size_bytes=int(item.size_bytes),
                    role=role,
                    mime_type=_mime_or_none(item.mime_type),
                )
            )
        return tuple(normalized), primary_count

    def _assert_primary_count(self, *, primary_count: int) -> None:
        if primary_count == 0:
            raise InputPrimaryDatasetMissingError()
        if primary_count > 1:
            raise InputPrimaryDatasetMultipleError(count=primary_count)

    def _persist_bundle(self, *, tenant_id: str, bundle: Bundle) -> None:
        payload = self._bundle_to_payload(bundle)
        raw = json.dumps(payload, ensure_ascii=False, separators=(",", ":"), sort_keys=True)
        encoded = raw.encode("utf-8")
        self._workspace.write_bytes(
            tenant_id=tenant_id,
            job_id=bundle.job_id,
            rel_path=BUNDLE_REL_PATH,
            data=encoded,
        )

    def create_bundle(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
        files: Sequence[BundleFileDeclaration],
    ) -> Bundle:
        self._assert_file_limit(file_count=len(files))
        normalized, primary_count = self._normalize_files(files=files)
        self._assert_primary_count(primary_count=primary_count)

        bundle = Bundle(
            bundle_id=f"bundle_{uuid.uuid4().hex}",
            job_id=job_id,
            files=normalized,
        )
        self._persist_bundle(tenant_id=tenant_id, bundle=bundle)
        return bundle

    def get_bundle(self, *, tenant_id: str = DEFAULT_TENANT_ID, job_id: str) -> Bundle:
        try:
            path = self._workspace.resolve_for_read(
                tenant_id=tenant_id,
                job_id=job_id,
                rel_path=BUNDLE_REL_PATH,
            )
        except FileNotFoundError as exc:
            raise BundleNotFoundError(job_id=job_id) from exc
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            raise BundleCorruptedError(job_id=job_id) from exc
        if not isinstance(raw, dict):
            raise BundleCorruptedError(job_id=job_id)
        return self._bundle_from_payload(job_id=job_id, payload=cast(JsonObject, raw))

    def _bundle_to_payload(self, bundle: Bundle) -> JsonObject:
        files: list[JsonObject] = []
        for item in bundle.files:
            files.append(
                {
                    "file_id": item.file_id,
                    "filename": item.filename,
                    "size_bytes": item.size_bytes,
                    "role": item.role,
                    "mime_type": item.mime_type,
                }
            )
        return cast(
            JsonObject,
            {
                "bundle_id": bundle.bundle_id,
                "job_id": bundle.job_id,
                "files": files,
            },
        )

    def _bundle_from_payload(self, *, job_id: str, payload: JsonObject) -> Bundle:
        bundle_id = payload.get("bundle_id")
        files = payload.get("files")
        if not isinstance(bundle_id, str) or bundle_id.strip() == "":
            raise BundleCorruptedError(job_id=job_id)
        if not isinstance(files, list):
            raise BundleCorruptedError(job_id=job_id)
        parsed_files: list[BundleFile] = []
        for item in files:
            if not isinstance(item, dict):
                raise BundleCorruptedError(job_id=job_id)
            parsed_files.append(self._file_from_payload(job_id=job_id, payload=item))
        return Bundle(bundle_id=bundle_id, job_id=job_id, files=tuple(parsed_files))

    def _file_from_payload(self, *, job_id: str, payload: dict[str, Any]) -> BundleFile:
        file_id = payload.get("file_id")
        filename = payload.get("filename")
        size_bytes = payload.get("size_bytes")
        role = payload.get("role")
        mime_type = payload.get("mime_type")
        if not isinstance(file_id, str) or file_id.strip() == "":
            raise BundleCorruptedError(job_id=job_id)
        if not isinstance(filename, str) or filename.strip() == "":
            raise BundleCorruptedError(job_id=job_id)
        if not isinstance(role, str) or role.strip() == "":
            raise BundleCorruptedError(job_id=job_id)
        if not isinstance(size_bytes, int):
            raise BundleCorruptedError(job_id=job_id)
        if mime_type is not None and not isinstance(mime_type, str):
            raise BundleCorruptedError(job_id=job_id)
        return BundleFile(
            file_id=file_id,
            filename=filename,
            size_bytes=size_bytes,
            role=role,
            mime_type=_mime_or_none(mime_type),
        )
