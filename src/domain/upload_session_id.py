from __future__ import annotations

import uuid

UPLOAD_SESSION_ID_PREFIX = "usv1"


def build_upload_session_id(*, job_id: str) -> str:
    return f"{UPLOAD_SESSION_ID_PREFIX}.{job_id}.{uuid.uuid4().hex}"


def job_id_from_upload_session_id(upload_session_id: str) -> str:
    parts = upload_session_id.split(".")
    if len(parts) != 3 or parts[0] != UPLOAD_SESSION_ID_PREFIX:
        raise ValueError("invalid upload_session_id")
    job_id = parts[1].strip()
    nonce = parts[2].strip()
    if job_id == "" or nonce == "":
        raise ValueError("invalid upload_session_id")
    return job_id

