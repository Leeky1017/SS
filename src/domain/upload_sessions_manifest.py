from __future__ import annotations

from typing import cast

from src.domain.inputs_manifest import MANIFEST_REL_PATH, PreparedDataset, read_manifest_json
from src.domain.job_store import JobStore
from src.domain.job_workspace_store import JobWorkspaceStore
from src.domain.models import ArtifactKind, ArtifactRef, JobInputs
from src.infra.upload_session_exceptions import UploadPartsInvalidError
from src.utils.json_types import JsonObject
from src.utils.tenancy import DEFAULT_TENANT_ID


def load_or_init_manifest(
    *,
    workspace: JobWorkspaceStore,
    tenant_id: str = DEFAULT_TENANT_ID,
    job_id: str,
) -> JsonObject:
    try:
        path = workspace.resolve_for_read(
            tenant_id=tenant_id,
            job_id=job_id,
            rel_path=MANIFEST_REL_PATH,
        )
    except FileNotFoundError:
        return cast(JsonObject, {"schema_version": 2, "datasets": []})
    return read_manifest_json(path)


def upsert_manifest_dataset(*, manifest: JsonObject, dataset: PreparedDataset) -> JsonObject:
    raw_datasets = _manifest_datasets_list(manifest=manifest)
    updated: list[JsonObject] = []
    for item in raw_datasets:
        key = item.get("dataset_key")
        if key == dataset.dataset_key:
            if item.get("role") != dataset.role:
                raise UploadPartsInvalidError(reason="dataset_key_role_conflict")
            continue
        updated.append(item)
    updated.append(_dataset_payload(dataset=dataset))
    return cast(JsonObject, {"schema_version": 2, "datasets": updated})


def prepared_datasets_from_manifest(*, manifest: JsonObject) -> list[PreparedDataset]:
    raw_datasets = _manifest_datasets_list(manifest=manifest)
    prepared: list[PreparedDataset] = []
    for item in raw_datasets:
        parsed = _prepared_dataset_from_item(item=item)
        if parsed is not None:
            prepared.append(parsed)
    return prepared


def update_job_inputs(
    *,
    store: JobStore,
    tenant_id: str = DEFAULT_TENANT_ID,
    job_id: str,
    dataset_rel_path: str,
    fingerprint: str,
) -> None:
    job = store.load(tenant_id=tenant_id, job_id=job_id)
    if job.inputs is None:
        job.inputs = JobInputs()
    job.inputs.manifest_rel_path = MANIFEST_REL_PATH
    job.inputs.fingerprint = fingerprint
    index_inputs_artifacts(job=job, dataset_rel_path=dataset_rel_path)
    store.save(tenant_id=tenant_id, job=job)


def index_inputs_artifacts(*, job, dataset_rel_path: str) -> None:
    known = {(ref.kind, ref.rel_path) for ref in job.artifacts_index}
    manifest_ref = ArtifactRef(kind=ArtifactKind.INPUTS_MANIFEST, rel_path=MANIFEST_REL_PATH)
    key = (manifest_ref.kind, manifest_ref.rel_path)
    if key not in known:
        job.artifacts_index.append(manifest_ref)
        known.add(key)
    dataset_ref = ArtifactRef(kind=ArtifactKind.INPUTS_DATASET, rel_path=dataset_rel_path)
    key = (dataset_ref.kind, dataset_ref.rel_path)
    if key not in known:
        job.artifacts_index.append(dataset_ref)


def _manifest_datasets_list(*, manifest: JsonObject) -> list[JsonObject]:
    datasets_obj = manifest.get("datasets", [])
    if not isinstance(datasets_obj, list):
        raise UploadPartsInvalidError(reason="manifest_datasets_invalid")
    parsed: list[JsonObject] = []
    for item in datasets_obj:
        if isinstance(item, dict):
            parsed.append(cast(JsonObject, item))
    return parsed


def _dataset_payload(*, dataset: PreparedDataset) -> JsonObject:
    return cast(
        JsonObject,
        {
            "dataset_key": dataset.dataset_key,
            "role": dataset.role,
            "rel_path": dataset.rel_path,
            "original_name": dataset.original_name,
            "size_bytes": dataset.size_bytes,
            "sha256": dataset.sha256,
            "fingerprint": dataset.fingerprint,
            "format": dataset.format,
            "uploaded_at": dataset.uploaded_at,
            "content_type": dataset.content_type,
        },
    )


def _prepared_dataset_from_item(*, item: JsonObject) -> PreparedDataset | None:
    dataset_key = item.get("dataset_key")
    role = item.get("role")
    rel_path = item.get("rel_path")
    sha256 = item.get("sha256")
    fingerprint = item.get("fingerprint")
    fmt = item.get("format")
    original_name = item.get("original_name")
    size_bytes = item.get("size_bytes")
    uploaded_at = item.get("uploaded_at")
    content_type = item.get("content_type")
    if not isinstance(dataset_key, str) or dataset_key.strip() == "":
        return None
    if not isinstance(role, str) or role.strip() == "":
        return None
    if not isinstance(rel_path, str) or rel_path.strip() == "":
        return None
    if not isinstance(sha256, str) or sha256.strip() == "":
        return None
    if not isinstance(fingerprint, str) or fingerprint.strip() == "":
        return None
    if not isinstance(fmt, str) or fmt.strip() == "":
        return None
    if not isinstance(original_name, str) or original_name.strip() == "":
        return None
    if not isinstance(size_bytes, int):
        return None
    if not isinstance(uploaded_at, str) or uploaded_at.strip() == "":
        return None
    if content_type is not None and not isinstance(content_type, str):
        return None
    return PreparedDataset(
        dataset_key=dataset_key,
        role=role,
        rel_path=rel_path,
        sha256=sha256,
        fingerprint=fingerprint,
        format=fmt,
        original_name=original_name,
        size_bytes=size_bytes,
        uploaded_at=uploaded_at,
        content_type=None if content_type is None else str(content_type),
        data=b"",
    )

