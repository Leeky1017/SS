from __future__ import annotations

import json
from io import BytesIO

import pytest
from openpyxl import Workbook

from src.api import deps
from src.domain.job_inputs_service import JobInputsService
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.main import create_app
from src.utils.job_workspace import resolve_job_dir
from tests.asgi_client import asgi_client
from tests.async_overrides import async_override

pytestmark = pytest.mark.anyio


def _xlsx_bytes() -> bytes:
    wb = Workbook()
    sheet1 = wb.active
    sheet1.title = "Sheet1"
    sheet1.append(["a", "b"])
    sheet1.append([1, 2])
    sheet2 = wb.create_sheet("Sheet2")
    sheet2.append(["x", "y"])
    sheet2.append([3, 4])
    bio = BytesIO()
    wb.save(bio)
    return bio.getvalue()


def _svc(*, store, jobs_dir) -> JobInputsService:
    return JobInputsService(store=store, workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir))


def _app(*, svc: JobInputsService, store, jobs_dir):
    app = create_app()
    app.dependency_overrides[deps.get_job_inputs_service] = async_override(svc)
    app.dependency_overrides[deps.get_job_store] = async_override(store)
    app.dependency_overrides[deps.get_job_workspace_store] = async_override(
        FileJobWorkspaceStore(jobs_dir=jobs_dir)
    )
    return app


async def test_select_primary_excel_sheet_persists_to_manifest_and_updates_preview(
    job_service, store, jobs_dir
) -> None:
    # Arrange
    job = job_service.create_job(requirement="hello")
    app = _app(svc=_svc(store=store, jobs_dir=jobs_dir), store=store, jobs_dir=jobs_dir)
    xlsx_bytes = _xlsx_bytes()

    # Act
    async with asgi_client(app=app) as client:
        uploaded = await client.post(
            f"/v1/jobs/{job.job_id}/inputs/upload",
            files={
                "file": (
                    "data.xlsx",
                    xlsx_bytes,
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                )
            },
        )
        selected = await client.post(
            f"/v1/jobs/{job.job_id}/inputs/primary/sheet",
            params={"sheet_name": "Sheet2", "rows": 20, "columns": 10},
        )

    # Assert
    assert uploaded.status_code == 200
    assert selected.status_code == 200
    payload = selected.json()
    assert payload["selected_sheet"] == "Sheet2"
    assert "Sheet1" in payload["sheet_names"]
    assert "Sheet2" in payload["sheet_names"]
    assert [c["name"] for c in payload["columns"]] == ["x", "y"]

    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job.job_id)
    assert job_dir is not None
    manifest = json.loads((job_dir / "inputs" / "manifest.json").read_text(encoding="utf-8"))
    datasets = manifest.get("datasets", [])
    assert isinstance(datasets, list)
    primary = next((d for d in datasets if d.get("role") == "primary_dataset"), None)
    assert isinstance(primary, dict)
    assert primary.get("sheet_name") == "Sheet2"
    assert primary.get("header_row") is True
