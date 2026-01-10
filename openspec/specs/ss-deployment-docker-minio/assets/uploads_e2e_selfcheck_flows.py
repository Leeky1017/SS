from __future__ import annotations

import time
from pathlib import Path

from uploads_e2e_selfcheck_core import (
    ComposeConfig,
    die,
    http_json,
    put_bytes,
    slice_part_bytes,
    verify_inputs,
)


def create_job(*, base_url: str, label: str) -> tuple[str, str]:
    payload = http_json(
        method="POST",
        url=f"{base_url}/v1/task-codes/redeem",
        payload={"task_code": f"selfcheck-{label}-{int(time.time())}", "requirement": f"uploads selfcheck {label}"},
    )
    return str(payload["job_id"]), str(payload["token"])


def create_bundle(
    *,
    base_url: str,
    job_id: str,
    token: str,
    filename: str,
    size_bytes: int,
) -> tuple[str, str]:
    payload = http_json(
        method="POST",
        url=f"{base_url}/v1/jobs/{job_id}/inputs/bundle",
        token=token,
        payload={
            "files": [
                {
                    "filename": filename,
                    "size_bytes": size_bytes,
                    "role": "primary_dataset",
                    "mime_type": "text/csv",
                }
            ]
        },
    )
    return str(payload["bundle_id"]), str(payload["files"][0]["file_id"])


def create_upload_session(
    *,
    base_url: str,
    job_id: str,
    token: str,
    bundle_id: str,
    file_id: str,
) -> dict[str, object]:
    return http_json(
        method="POST",
        url=f"{base_url}/v1/jobs/{job_id}/inputs/upload-sessions",
        token=token,
        payload={"bundle_id": bundle_id, "file_id": file_id},
    )


def _refresh_part1_url(*, base_url: str, token: str, upload_session_id: str) -> str:
    refresh = http_json(
        method="POST",
        url=f"{base_url}/v1/upload-sessions/{upload_session_id}/refresh-urls",
        token=token,
        payload={"part_numbers": [1]},
    )
    for item in refresh.get("parts", []):
        if item.get("part_number") == 1:
            url = str(item.get("url", ""))
            if url.strip() != "":
                return url
    die(f"refresh-urls missing part 1: {refresh}")


def _upload_multipart_parts(
    *,
    file_path: Path,
    part_size: int,
    presigned_urls: list[object],
    refreshed_part1_url: str,
) -> list[dict[str, object]]:
    parts: list[dict[str, object]] = []
    for item in presigned_urls:
        part_number = int(item["part_number"])
        url = str(item["url"])
        if part_number == 1:
            url = refreshed_part1_url
        etag = put_bytes(url=url, data=slice_part_bytes(file_path=file_path, part_size=part_size, part_number=part_number))
        if etag is None or etag.strip() == "":
            die(f"missing ETag for part {part_number}")
        parts.append({"part_number": part_number, "etag": etag})
    return parts


def direct_flow(*, base_url: str, compose_cfg: ComposeConfig, file_path: Path) -> None:
    job_id, token = create_job(base_url=base_url, label="direct")
    bundle_id, file_id = create_bundle(
        base_url=base_url,
        job_id=job_id,
        token=token,
        filename="direct.csv",
        size_bytes=file_path.stat().st_size,
    )
    session = create_upload_session(
        base_url=base_url,
        job_id=job_id,
        token=token,
        bundle_id=bundle_id,
        file_id=file_id,
    )
    if session.get("upload_strategy") != "direct":
        die(f"expected upload_strategy=direct, got: {session}")
    upload_session_id = str(session["upload_session_id"])
    presigned_url = str(session["presigned_url"])

    put_bytes(url=presigned_url, data=file_path.read_bytes())
    finalize = http_json(
        method="POST",
        url=f"{base_url}/v1/upload-sessions/{upload_session_id}/finalize",
        token=token,
        payload={"parts": []},
    )
    if finalize.get("success") is not True:
        die(f"direct finalize failed: {finalize}")
    row_count = verify_inputs(
        base_url=base_url,
        compose_cfg=compose_cfg,
        job_id=job_id,
        token=token,
        original_name="direct.csv",
    )
    print(f"Direct OK: job_id={job_id} row_count={row_count}")


def multipart_flow(*, base_url: str, compose_cfg: ComposeConfig, file_path: Path) -> None:
    job_id, token = create_job(base_url=base_url, label="multipart")
    bundle_id, file_id = create_bundle(
        base_url=base_url,
        job_id=job_id,
        token=token,
        filename="multipart.csv",
        size_bytes=file_path.stat().st_size,
    )
    session = create_upload_session(
        base_url=base_url,
        job_id=job_id,
        token=token,
        bundle_id=bundle_id,
        file_id=file_id,
    )
    if session.get("upload_strategy") != "multipart":
        die(f"expected upload_strategy=multipart, got: {session}")
    upload_session_id = str(session["upload_session_id"])
    part_size = int(session["part_size"])
    presigned_urls = session.get("presigned_urls")
    if not isinstance(presigned_urls, list) or len(presigned_urls) < 1:
        die(f"multipart presigned_urls missing: {session}")

    refreshed_part1_url = _refresh_part1_url(base_url=base_url, token=token, upload_session_id=upload_session_id)
    parts = _upload_multipart_parts(
        file_path=file_path,
        part_size=part_size,
        presigned_urls=presigned_urls,
        refreshed_part1_url=refreshed_part1_url,
    )
    finalize = http_json(
        method="POST",
        url=f"{base_url}/v1/upload-sessions/{upload_session_id}/finalize",
        token=token,
        payload={"parts": parts},
    )
    if finalize.get("success") is not True:
        die(f"multipart finalize failed: {finalize}")
    row_count = verify_inputs(
        base_url=base_url,
        compose_cfg=compose_cfg,
        job_id=job_id,
        token=token,
        original_name="multipart.csv",
    )
    print(f"Multipart OK: job_id={job_id} parts={len(parts)} row_count={row_count}")

