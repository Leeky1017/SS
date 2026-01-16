from __future__ import annotations

from io import BytesIO

import httpx
import pytest

from tests.v1_redeem import redeem_job

pytestmark = pytest.mark.anyio

XLSX_MIME = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
_OLE_SIGNATURE = bytes.fromhex("D0CF11E0A1B11AE1")


def _xlsx_bytes(
    *,
    sheets: dict[str, list[list[object]]],
    hidden_sheets: set[str] | None = None,
) -> bytes:
    openpyxl = pytest.importorskip("openpyxl")
    workbook = openpyxl.Workbook()
    default_sheet = workbook.active
    workbook.remove(default_sheet)
    hidden = set() if hidden_sheets is None else set(hidden_sheets)
    for name, rows in sheets.items():
        ws = workbook.create_sheet(title=name)
        if name in hidden:
            ws.sheet_state = "hidden"
        for row in rows:
            ws.append(list(row))
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


async def test_password_protected_xlsx_preview_returns_400_with_friendly_message(
    e2e_client: httpx.AsyncClient,
) -> None:
    job_id, _token = await redeem_job(
        client=e2e_client,
        task_code="tc_e2e_inputs_xlsx_password_protected",
        requirement="req",
    )
    fake_encrypted = _OLE_SIGNATURE + b"\x00" * 512
    uploaded = await _upload_single(
        client=e2e_client,
        job_id=job_id,
        filename="primary.xlsx",
        content=fake_encrypted,
        content_type=XLSX_MIME,
    )
    assert uploaded.status_code == 200

    preview = await e2e_client.get(f"/v1/jobs/{job_id}/inputs/preview")
    assert preview.status_code == 400
    payload = preview.json()
    assert payload["error_code"] == "INPUT_PARSE_FAILED"
    assert "password" in payload["message"].lower() or "encrypt" in payload["message"].lower()


async def test_xlsx_hidden_sheets_are_excluded_from_sheet_names(
    e2e_client: httpx.AsyncClient,
) -> None:
    job_id, _token = await redeem_job(
        client=e2e_client,
        task_code="tc_e2e_inputs_xlsx_hidden_sheets",
        requirement="req",
    )
    content = _xlsx_bytes(
        sheets={
            "Visible": [["id", "y"], [1, 2]],
            "Hidden": [["id", "y"], [3, 4]],
        },
        hidden_sheets={"Hidden"},
    )
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
    assert payload["sheet_names"] == ["Visible"]
    assert payload["selected_sheet"] == "Visible"


async def test_xlsx_formula_cells_return_raw_formula_strings_in_preview(
    e2e_client: httpx.AsyncClient,
) -> None:
    job_id, _token = await redeem_job(
        client=e2e_client,
        task_code="tc_e2e_inputs_xlsx_formula_cells",
        requirement="req",
    )
    content = _xlsx_bytes(
        sheets={"Sheet1": [["id", "y", "x", "sum"], [1, 2, 3, "=B2+C2"]]},
    )
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
    rows = preview.json()["sample_rows"]
    assert rows and rows[0]["sum"] == "=B2+C2"


async def test_large_csv_preview_completes_and_row_count_is_reported(
    e2e_client: httpx.AsyncClient,
) -> None:
    job_id, _token = await redeem_job(
        client=e2e_client,
        task_code="tc_e2e_inputs_csv_large",
        requirement="req",
    )
    header = b"id,y,x\n"
    rows = b"1,2,3\n" * 200_000
    uploaded = await _upload_single(
        client=e2e_client,
        job_id=job_id,
        filename="primary.csv",
        content=header + rows,
        content_type="text/csv",
    )
    assert uploaded.status_code == 200

    preview = await e2e_client.get(f"/v1/jobs/{job_id}/inputs/preview")
    assert preview.status_code == 200
    assert preview.json()["row_count"] in {200_000, None}


async def test_pathological_excel_column_names_are_normalized_or_preserved_safely(
    e2e_client: httpx.AsyncClient,
) -> None:
    job_id, _token = await redeem_job(
        client=e2e_client,
        task_code="tc_e2e_inputs_xlsx_pathological_columns",
        requirement="req",
    )
    long_name = "a" * 300
    content = _xlsx_bytes(
        sheets={
            "Sheet1": [
                [long_name, "name\nwith\nnewlines", 123, 456, "!!!"],
                [1, 2, 3, 4, 5],
            ]
        },
    )
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
    names = [c["name"] for c in preview.json()["columns"]]
    assert names[0] == long_name
    assert names[1] == "name with newlines"
    assert names[2] == "col_3"
    assert names[3] == "col_4"
