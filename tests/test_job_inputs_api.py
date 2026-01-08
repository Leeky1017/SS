from __future__ import annotations

import hashlib
import json

from fastapi.testclient import TestClient

from src.api import deps
from src.domain.job_inputs_service import JobInputsService
from src.domain.models import ArtifactKind
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.main import create_app
from src.utils.job_workspace import resolve_job_dir


def _sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _dataset_key(data: bytes) -> str:
    return f"ds_{_sha256_hex(data)[:16]}"


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
    assert uploaded_payload["fingerprint"].startswith("sha256:")

    assert preview.status_code == 200
    preview_payload = preview.json()
    assert preview_payload["job_id"] == job.job_id
    assert [c["name"] for c in preview_payload["columns"]] == ["age", "income"]
    assert len(preview_payload["sample_rows"]) == 2

    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job.job_id)
    assert job_dir is not None
    dataset_key = _dataset_key(csv_bytes)
    dataset_rel_path = f"inputs/{dataset_key}.csv"
    assert (job_dir / "inputs" / f"{dataset_key}.csv").read_bytes() == csv_bytes
    manifest = json.loads((job_dir / "inputs" / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["schema_version"] == 2
    datasets = manifest["datasets"]
    assert isinstance(datasets, list)
    assert len(datasets) == 1
    dataset = datasets[0]
    assert dataset["content_type"] == "text/csv"
    assert dataset["dataset_key"] == dataset_key
    assert dataset["fingerprint"] == f"sha256:{_sha256_hex(csv_bytes)}"
    assert dataset["format"] == "csv"
    assert dataset["original_name"] == "data.csv"
    assert dataset["rel_path"] == dataset_rel_path
    assert dataset["sha256"] == _sha256_hex(csv_bytes)
    assert dataset["size_bytes"] == len(csv_bytes)
    assert dataset["role"] == "primary_dataset"
    uploaded_at = dataset.get("uploaded_at")
    assert isinstance(uploaded_at, str)
    assert uploaded_at.strip() != ""

    persisted = store.load(job.job_id)
    assert persisted.inputs is not None
    assert persisted.inputs.manifest_rel_path == "inputs/manifest.json"
    assert persisted.inputs.fingerprint == uploaded_payload["fingerprint"]
    assert any(
        ref.kind == ArtifactKind.INPUTS_MANIFEST and ref.rel_path == "inputs/manifest.json"
        for ref in persisted.artifacts_index
    )
    assert any(
        ref.kind == ArtifactKind.INPUTS_DATASET and ref.rel_path == dataset_rel_path
        for ref in persisted.artifacts_index
    )


def test_upload_two_csvs_with_roles_is_deterministic_across_order(
    job_service, store, jobs_dir
) -> None:
    # Arrange
    svc = _svc(store=store, jobs_dir=jobs_dir)
    client = _client(svc=svc)
    csv_a = b"age,income\n30,1000\n"
    csv_b = b"id,y\n1,2\n"
    job_multi = job_service.create_job(requirement="hello")

    # Act
    uploaded = client.post(
        f"/v1/jobs/{job_multi.job_id}/inputs/upload",
        files=[
            ("file", ("a.csv", csv_a, "text/csv")),
            ("file", ("b.csv", csv_b, "text/csv")),
        ],
        data={"role": ["primary_dataset", "secondary_dataset"]},
    )
    uploaded_reordered = client.post(
        f"/v1/jobs/{job_multi.job_id}/inputs/upload",
        files=[
            ("file", ("b.csv", csv_b, "text/csv")),
            ("file", ("a.csv", csv_a, "text/csv")),
        ],
        data={"role": ["secondary_dataset", "primary_dataset"]},
    )
    job_single = job_service.create_job(requirement="hello-single")
    uploaded_single = client.post(
        f"/v1/jobs/{job_single.job_id}/inputs/upload",
        files={"file": ("a.csv", csv_a, "text/csv")},
    )

    # Assert
    assert uploaded.status_code == 200
    assert uploaded_reordered.status_code == 200
    assert uploaded_single.status_code == 200
    fp_multi = uploaded.json()["fingerprint"]
    assert fp_multi == uploaded_reordered.json()["fingerprint"]
    assert fp_multi != uploaded_single.json()["fingerprint"]

    key_a = _dataset_key(csv_a)
    key_b = _dataset_key(csv_b)
    rel_a = f"inputs/{key_a}.csv"
    rel_b = f"inputs/{key_b}.csv"
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job_multi.job_id)
    assert job_dir is not None
    assert (job_dir / rel_a).read_bytes() == csv_a
    assert (job_dir / rel_b).read_bytes() == csv_b
    manifest = json.loads((job_dir / "inputs" / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["schema_version"] == 2
    roles = sorted([d["role"] for d in manifest["datasets"]])
    assert roles == ["primary_dataset", "secondary_dataset"]
    assert {d["rel_path"] for d in manifest["datasets"]} == {rel_a, rel_b}

    persisted = store.load(job_multi.job_id)
    assert persisted.inputs is not None
    assert persisted.inputs.fingerprint == fp_multi
    assert any(
        ref.kind == ArtifactKind.INPUTS_DATASET and ref.rel_path == rel_a
        for ref in persisted.artifacts_index
    )
    assert any(
        ref.kind == ArtifactKind.INPUTS_DATASET and ref.rel_path == rel_b
        for ref in persisted.artifacts_index
    )


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
