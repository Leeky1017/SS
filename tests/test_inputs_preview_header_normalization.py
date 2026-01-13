from __future__ import annotations

from io import BytesIO

import pytest
from openpyxl import Workbook

from src.api import deps
from src.domain.job_inputs_service import JobInputsService
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.main import create_app
from tests.asgi_client import asgi_client
from tests.async_overrides import async_override

pytestmark = pytest.mark.anyio


def _xlsx_with_blank_header() -> bytes:
    wb = Workbook()
    sheet = wb.active
    sheet.title = "Sheet1"
    sheet.append(["a", "", "c"])
    sheet.append([1, 2, 3])
    bio = BytesIO()
    wb.save(bio)
    return bio.getvalue()


def _svc(*, store, jobs_dir) -> JobInputsService:
    return JobInputsService(store=store, workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir))


def _app(*, svc: JobInputsService):
    app = create_app()
    app.dependency_overrides[deps.get_job_inputs_service] = async_override(svc)
    return app


async def test_preview_excel_with_blank_header_normalizes_unnamed_columns(
    job_service, store, jobs_dir
) -> None:
    # Arrange
    job = job_service.create_job(requirement="hello")
    app = _app(svc=_svc(store=store, jobs_dir=jobs_dir))
    xlsx_bytes = _xlsx_with_blank_header()

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
        previewed = await client.get(
            f"/v1/jobs/{job.job_id}/inputs/preview",
            params={"rows": 5, "columns": 10},
        )

    # Assert
    assert uploaded.status_code == 200
    assert previewed.status_code == 200
    payload = previewed.json()
    names = [col["name"] for col in payload["columns"]]
    assert names[0] == "a"
    assert names[1] == "col_2"
    assert "Unnamed" not in " ".join(names)
