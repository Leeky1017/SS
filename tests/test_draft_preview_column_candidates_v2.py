from __future__ import annotations

import json
from io import BytesIO

import pytest
from openpyxl import Workbook

from src.api import deps
from src.domain.inputs_sheet_selection_service import InputsSheetSelectionService
from src.domain.job_inputs_service import JobInputsService
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.main import create_app
from src.utils.job_workspace import resolve_job_dir
from tests.asgi_client import asgi_client
from tests.async_overrides import async_override

pytestmark = pytest.mark.anyio


def _app(*, job_inputs_service: JobInputsService, draft_service):  # noqa: ANN001
    app = create_app()
    app.dependency_overrides[deps.get_job_inputs_service] = async_override(job_inputs_service)
    app.dependency_overrides[deps.get_draft_service] = async_override(draft_service)
    return app


def _xlsx_bytes_with_two_sheets(*, sheet1_cols: list[str], sheet2_cols: list[str]) -> bytes:
    wb = Workbook()
    sheet1 = wb.active
    sheet1.title = "Sheet1"
    sheet1.append(sheet1_cols)
    sheet1.append([1 for _ in sheet1_cols])
    sheet2 = wb.create_sheet("Sheet2")
    sheet2.append(sheet2_cols)
    sheet2.append([1 for _ in sheet2_cols])
    bio = BytesIO()
    wb.save(bio)
    return bio.getvalue()


async def test_draft_preview_includes_auxiliary_columns_in_candidates_v2(
    job_service, store, jobs_dir, draft_service
) -> None:
    job = job_service.create_job(requirement="hello")
    job_inputs_service = JobInputsService(
        store=store,
        workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir),
    )
    app = _app(job_inputs_service=job_inputs_service, draft_service=draft_service)

    async with asgi_client(app=app) as client:
        uploaded = await client.post(
            f"/v1/jobs/{job.job_id}/inputs/upload",
            files=[
                ("file", ("main.csv", b"a,b\n1,2\n", "text/csv")),
                ("file", ("aux.csv", b"x,y\n3,4\n", "text/csv")),
            ],
            data={"role": ["primary_dataset", "auxiliary_data"]},
        )
        assert uploaded.status_code == 200

        preview = await client.get(f"/v1/jobs/{job.job_id}/draft/preview")
        assert preview.status_code == 200
        payload = preview.json()

    assert payload["status"] == "ready"
    assert set(payload["column_candidates"]) >= {"a", "b", "x", "y"}

    v2 = payload["column_candidates_v2"]
    assert any(item["role"] == "primary_dataset" and item["name"] == "a" for item in v2)
    assert any(item["role"] == "primary_dataset" and item["name"] == "b" for item in v2)
    assert any(item["role"] == "auxiliary_data" and item["name"] == "x" for item in v2)
    assert any(item["role"] == "auxiliary_data" and item["name"] == "y" for item in v2)
    assert all(
        isinstance(item.get("dataset_key"), str) and item["dataset_key"].strip() != ""
        for item in v2
    )


async def test_draft_preview_uses_selected_auxiliary_excel_sheet_for_candidates_v2(
    job_service, store, jobs_dir, draft_service
) -> None:
    job = job_service.create_job(requirement="hello")
    workspace = FileJobWorkspaceStore(jobs_dir=jobs_dir)
    job_inputs_service = JobInputsService(store=store, workspace=workspace)
    app = _app(job_inputs_service=job_inputs_service, draft_service=draft_service)
    auxiliary_excel = _xlsx_bytes_with_two_sheets(sheet1_cols=["x", "y"], sheet2_cols=["u", "v"])

    async with asgi_client(app=app) as client:
        uploaded = await client.post(
            f"/v1/jobs/{job.job_id}/inputs/upload",
            files=[
                ("file", ("main.csv", b"a,b\n1,2\n", "text/csv")),
                (
                    "file",
                    (
                        "aux.xlsx",
                        auxiliary_excel,
                        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                    ),
                ),
            ],
            data={"role": ["primary_dataset", "auxiliary_data"]},
        )
        assert uploaded.status_code == 200

        job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job.job_id)
        assert job_dir is not None
        manifest = json.loads((job_dir / "inputs" / "manifest.json").read_text(encoding="utf-8"))
        datasets = manifest.get("datasets", [])
        assert isinstance(datasets, list)
        auxiliary = next((d for d in datasets if d.get("role") == "auxiliary_data"), None)
        assert isinstance(auxiliary, dict)
        dataset_key = auxiliary.get("dataset_key")
        assert isinstance(dataset_key, str) and dataset_key.strip() != ""

        InputsSheetSelectionService(store=store, workspace=workspace).select_dataset_excel_sheet(
            job_id=job.job_id,
            dataset_key=dataset_key,
            sheet_name="Sheet2",
        )

        preview = await client.get(f"/v1/jobs/{job.job_id}/draft/preview")
        assert preview.status_code == 200
        payload = preview.json()

    assert payload["status"] == "ready"
    v2 = payload["column_candidates_v2"]
    auxiliary_names = {item["name"] for item in v2 if item.get("role") == "auxiliary_data"}
    assert "u" in auxiliary_names
    assert "v" in auxiliary_names
    assert "x" not in auxiliary_names
    assert "y" not in auxiliary_names
