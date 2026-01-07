from __future__ import annotations

import hashlib
import json

from fastapi.testclient import TestClient

from src.api import deps
from src.domain.job_inputs_service import JobInputsService
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.main import create_app
from src.utils.job_workspace import resolve_job_dir


def _client(*, svc: JobInputsService) -> TestClient:
    app = create_app()
    app.dependency_overrides[deps.get_job_inputs_service] = lambda: svc
    return TestClient(app)


def _svc(*, store, jobs_dir) -> JobInputsService:
    return JobInputsService(store=store, workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir))


def test_upload_csv_and_preview_returns_columns_and_rows(job_service, store, jobs_dir) -> None:
    # Arrange
    job = job_service.create_job(requirement="hello")
    svc = _svc(store=store, jobs_dir=jobs_dir)
    client = _client(svc=svc)
    csv_bytes = b"age,income\n30,1000\n40,2000\n"

    # Act
    uploaded = client.post(
        f"/v1/jobs/{job.job_id}/inputs/upload",
        files={"file": ("data.csv", csv_bytes, "text/csv")},
    )
    preview = client.get(f"/v1/jobs/{job.job_id}/inputs/preview")

    # Assert
    assert uploaded.status_code == 200
    uploaded_payload = uploaded.json()
    assert uploaded_payload["job_id"] == job.job_id
    assert uploaded_payload["manifest_rel_path"] == "inputs/manifest.json"
    assert uploaded_payload["fingerprint"] == f"sha256:{hashlib.sha256(csv_bytes).hexdigest()}"

    assert preview.status_code == 200
    preview_payload = preview.json()
    assert preview_payload["job_id"] == job.job_id
    assert [c["name"] for c in preview_payload["columns"]] == ["age", "income"]
    assert len(preview_payload["sample_rows"]) == 2

    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job.job_id)
    assert job_dir is not None
    assert (job_dir / "inputs" / "primary.csv").read_bytes() == csv_bytes
    manifest = json.loads((job_dir / "inputs" / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["schema_version"] == 1
    assert manifest["primary_dataset"]["rel_path"] == "inputs/primary.csv"

    persisted = store.load(job.job_id)
    assert persisted.inputs is not None
    assert persisted.inputs.manifest_rel_path == "inputs/manifest.json"
    assert persisted.inputs.fingerprint == uploaded_payload["fingerprint"]


def test_upload_with_empty_file_returns_input_empty_file(job_service, store, jobs_dir) -> None:
    client = _client(svc=_svc(store=store, jobs_dir=jobs_dir))
    job = job_service.create_job(requirement="hello")

    response = client.post(
        f"/v1/jobs/{job.job_id}/inputs/upload",
        files={"file": ("data.csv", b"", "text/csv")},
    )

    assert response.status_code == 400
    assert response.json()["error_code"] == "INPUT_EMPTY_FILE"


def test_upload_with_unsupported_extension_returns_input_unsupported_format(
    job_service, store, jobs_dir
) -> None:
    client = _client(svc=_svc(store=store, jobs_dir=jobs_dir))
    job = job_service.create_job(requirement="hello")

    response = client.post(
        f"/v1/jobs/{job.job_id}/inputs/upload",
        files={"file": ("data.txt", b"hello", "text/plain")},
    )

    assert response.status_code == 400
    assert response.json()["error_code"] == "INPUT_UNSUPPORTED_FORMAT"


def test_preview_with_malformed_csv_returns_input_parse_failed(
    job_service, store, jobs_dir
) -> None:
    client = _client(svc=_svc(store=store, jobs_dir=jobs_dir))
    job = job_service.create_job(requirement="hello")

    uploaded = client.post(
        f"/v1/jobs/{job.job_id}/inputs/upload",
        files={"file": ("data.csv", b"\xff\xfe\xff", "text/csv")},
    )
    assert uploaded.status_code == 200

    preview = client.get(f"/v1/jobs/{job.job_id}/inputs/preview")

    assert preview.status_code == 400
    assert preview.json()["error_code"] == "INPUT_PARSE_FAILED"


def test_upload_with_path_traversal_filename_returns_input_filename_unsafe(
    job_service, store, jobs_dir
) -> None:
    client = _client(svc=_svc(store=store, jobs_dir=jobs_dir))
    job = job_service.create_job(requirement="hello")

    response = client.post(
        f"/v1/jobs/{job.job_id}/inputs/upload",
        files={"file": ("../evil.csv", b"a,b\n1,2\n", "text/csv")},
    )

    assert response.status_code == 400
    assert response.json()["error_code"] == "INPUT_FILENAME_UNSAFE"


def test_upload_when_cross_tenant_access_returns_404(job_service, store, jobs_dir) -> None:
    client = _client(svc=_svc(store=store, jobs_dir=jobs_dir))
    job = job_service.create_job(tenant_id="tenant-a", requirement="hello")

    response = client.post(
        f"/v1/jobs/{job.job_id}/inputs/upload",
        files={"file": ("data.csv", b"a,b\n1,2\n", "text/csv")},
        headers={"X-SS-Tenant-ID": "tenant-b"},
    )

    assert response.status_code == 404
    assert response.json()["error_code"] == "JOB_NOT_FOUND"
