from __future__ import annotations

from io import BytesIO

import httpx
import pytest

from tests.v1_redeem import redeem_job

pytestmark = pytest.mark.anyio

XLSX_MIME = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
XLS_MIME = "application/vnd.ms-excel"


def _xlsx_bytes(*, sheets: dict[str, list[list[object]]]) -> bytes:
    openpyxl = pytest.importorskip("openpyxl")
    workbook = openpyxl.Workbook()
    default_sheet = workbook.active
    workbook.remove(default_sheet)
    for name, rows in sheets.items():
        ws = workbook.create_sheet(title=name)
        for row in rows:
            ws.append(list(row))
    buf = BytesIO()
    workbook.save(buf)
    return buf.getvalue()


def _xls_bytes(*, rows: list[list[object]]) -> bytes:
    xlwt = pytest.importorskip("xlwt")
    workbook = xlwt.Workbook()
    ws = workbook.add_sheet("Sheet1")
    for r, row in enumerate(rows):
        for c, value in enumerate(row):
            ws.write(r, c, value)
    buf = BytesIO()
    workbook.save(buf)
    return buf.getvalue()


async def _upload_single(
    *,
    client: httpx.AsyncClient,
    job_id: str,
    filename: str,
    content: bytes,
    content_type: str,
) -> httpx.Response:
    files = [("file", (filename, content, content_type))]
    return await client.post(f"/v1/jobs/{job_id}/inputs/upload", files=files)


async def test_upload_csv_then_preview_succeeds(e2e_client: httpx.AsyncClient) -> None:
    job_id, _token = await redeem_job(
        client=e2e_client,
        task_code="tc_e2e_inputs_csv_ok",
        requirement="req",
    )
    uploaded = await _upload_single(
        client=e2e_client,
        job_id=job_id,
        filename="primary.csv",
        content=b"id,y,x\n1,2,3\n",
        content_type="text/csv",
    )
    assert uploaded.status_code == 200

    preview = await e2e_client.get(f"/v1/jobs/{job_id}/inputs/preview")
    assert preview.status_code == 200
    payload = preview.json()
    assert payload["job_id"] == job_id
    assert payload["row_count"] == 1
    assert payload["column_count"] == 3
    assert [c["name"] for c in payload["columns"]] == ["id", "y", "x"]


async def test_upload_csv_header_only_has_row_count_zero(e2e_client: httpx.AsyncClient) -> None:
    job_id, _token = await redeem_job(
        client=e2e_client,
        task_code="tc_e2e_inputs_csv_header_only",
        requirement="req",
    )
    uploaded = await _upload_single(
        client=e2e_client,
        job_id=job_id,
        filename="primary.csv",
        content=b"a,b\n",
        content_type="text/csv",
    )
    assert uploaded.status_code == 200

    preview = await e2e_client.get(f"/v1/jobs/{job_id}/inputs/preview")
    assert preview.status_code == 200
    payload = preview.json()
    assert payload["row_count"] == 0
    assert payload["column_count"] == 2


async def test_upload_xlsx_then_preview_succeeds(e2e_client: httpx.AsyncClient) -> None:
    job_id, _token = await redeem_job(
        client=e2e_client,
        task_code="tc_e2e_inputs_xlsx_ok",
        requirement="req",
    )
    content = _xlsx_bytes(sheets={"Sheet1": [["id", "y", "x"], [1, 2, 3]]})
    uploaded = await _upload_single(
        client=e2e_client,
        job_id=job_id,
        filename="primary.xlsx",
        content=content,
        content_type=XLSX_MIME,
    )
    assert uploaded.status_code == 200

    preview = await e2e_client.get(f"/v1/jobs/{job_id}/inputs/preview")
    assert preview.status_code == 200
    payload = preview.json()
    assert payload["job_id"] == job_id
    assert payload["sheet_names"] == ["Sheet1"]
    assert payload["selected_sheet"] == "Sheet1"


async def test_upload_xls_then_preview_succeeds(e2e_client: httpx.AsyncClient) -> None:
    job_id, _token = await redeem_job(
        client=e2e_client,
        task_code="tc_e2e_inputs_xls_ok",
        requirement="req",
    )
    content = _xls_bytes(rows=[["id", "y", "x"], [1, 2, 3]])
    uploaded = await _upload_single(
        client=e2e_client,
        job_id=job_id,
        filename="primary.xls",
        content=content,
        content_type=XLS_MIME,
    )
    assert uploaded.status_code == 200

    preview = await e2e_client.get(f"/v1/jobs/{job_id}/inputs/preview")
    assert preview.status_code == 200
    payload = preview.json()
    assert payload["sheet_names"]


@pytest.mark.parametrize(
    "filename,content_type",
    [
        ("data.txt", "text/plain"),
        ("data.zip", "application/zip"),
        ("img.png", "image/png"),
    ],
)
async def test_upload_unsupported_formats_returns_400(
    e2e_client: httpx.AsyncClient,
    filename: str,
    content_type: str,
) -> None:
    job_id, _token = await redeem_job(
        client=e2e_client,
        task_code=f"tc_e2e_inputs_unsupported_{filename}",
        requirement="req",
    )
    uploaded = await _upload_single(
        client=e2e_client,
        job_id=job_id,
        filename=filename,
        content=b"hello",
        content_type=content_type,
    )
    assert uploaded.status_code == 400
    assert uploaded.json()["error_code"] == "INPUT_UNSUPPORTED_FORMAT"


async def test_upload_empty_file_returns_400(e2e_client: httpx.AsyncClient) -> None:
    job_id, _token = await redeem_job(
        client=e2e_client,
        task_code="tc_e2e_inputs_empty_file",
        requirement="req",
    )
    uploaded = await _upload_single(
        client=e2e_client,
        job_id=job_id,
        filename="primary.csv",
        content=b"",
        content_type="text/csv",
    )
    assert uploaded.status_code == 400
    assert uploaded.json()["error_code"] == "INPUT_EMPTY_FILE"


async def test_csv_gbk_encoding_preview_returns_400(e2e_client: httpx.AsyncClient) -> None:
    job_id, _token = await redeem_job(
        client=e2e_client,
        task_code="tc_e2e_inputs_gbk",
        requirement="req",
    )
    gbk_bytes = "id,城市\n1,上海\n".encode("gbk")
    uploaded = await _upload_single(
        client=e2e_client,
        job_id=job_id,
        filename="primary.csv",
        content=gbk_bytes,
        content_type="text/csv",
    )
    assert uploaded.status_code == 200

    preview = await e2e_client.get(f"/v1/jobs/{job_id}/inputs/preview")
    assert preview.status_code == 400
    assert preview.json()["error_code"] == "INPUT_PARSE_FAILED"


async def test_excel_select_sheet_and_missing_sheet_returns_400(
    e2e_client: httpx.AsyncClient,
) -> None:
    job_id, _token = await redeem_job(
        client=e2e_client,
        task_code="tc_e2e_inputs_excel_sheets",
        requirement="req",
    )
    content = _xlsx_bytes(
        sheets={
            "SheetA": [["id", "y"], [1, 2]],
            "SheetB": [["id", "y"], [3, 4]],
        }
    )
    uploaded = await _upload_single(
        client=e2e_client,
        job_id=job_id,
        filename="primary.xlsx",
        content=content,
        content_type=XLSX_MIME,
    )
    assert uploaded.status_code == 200

    first = await e2e_client.get(f"/v1/jobs/{job_id}/inputs/preview")
    assert first.status_code == 200
    assert set(first.json()["sheet_names"]) == {"SheetA", "SheetB"}

    switched = await e2e_client.post(
        f"/v1/jobs/{job_id}/inputs/primary/sheet",
        params={"sheet_name": "SheetB"},
    )
    assert switched.status_code == 200
    assert switched.json()["selected_sheet"] == "SheetB"

    missing = await e2e_client.post(
        f"/v1/jobs/{job_id}/inputs/primary/sheet",
        params={"sheet_name": "Missing"},
    )
    assert missing.status_code == 400
    assert missing.json()["error_code"] == "INPUT_EXCEL_SHEET_NOT_FOUND"


async def test_corrupted_xlsx_preview_returns_400(e2e_client: httpx.AsyncClient) -> None:
    job_id, _token = await redeem_job(
        client=e2e_client,
        task_code="tc_e2e_inputs_xlsx_corrupted",
        requirement="req",
    )
    uploaded = await _upload_single(
        client=e2e_client,
        job_id=job_id,
        filename="primary.xlsx",
        content=b"not-a-zip",
        content_type=XLSX_MIME,
    )
    assert uploaded.status_code == 200

    preview = await e2e_client.get(f"/v1/jobs/{job_id}/inputs/preview")
    assert preview.status_code == 400
    assert preview.json()["error_code"] == "INPUT_PARSE_FAILED"
