from __future__ import annotations

from datetime import datetime, timedelta, timezone
from pathlib import Path

import pytest

from src.domain.task_code_store import TaskCodeRecord
from src.infra.auth_exceptions import TaskCodeRedeemConflictError
from src.infra.file_task_code_store import FileTaskCodeStore


def test_issue_codes_then_find_by_code_returns_record(tmp_path: Path) -> None:
    store = FileTaskCodeStore(data_dir=tmp_path)
    now = datetime(2026, 1, 1, 0, 0, 0, tzinfo=timezone.utc)

    issued = store.issue_codes(
        tenant_id="default",
        count=1,
        expires_at=now + timedelta(days=1),
        now=now,
    )

    assert len(issued) == 1
    record = issued[0]
    found = store.find_by_code(tenant_id="default", task_code=record.task_code)
    assert found is not None
    assert found.code_id == record.code_id


def test_mark_used_with_same_job_is_idempotent_and_other_job_conflicts(tmp_path: Path) -> None:
    store = FileTaskCodeStore(data_dir=tmp_path)
    now = datetime(2026, 1, 1, 0, 0, 0, tzinfo=timezone.utc)
    record = store.issue_codes(
        tenant_id="default",
        count=1,
        expires_at=now + timedelta(days=1),
        now=now,
    )[0]

    used = store.mark_used(code_id=record.code_id, job_id="job_1", used_at=now)
    assert used.job_id == "job_1"
    assert used.used_at == now.isoformat()

    again = store.mark_used(code_id=record.code_id, job_id="job_1", used_at=now)
    assert again.job_id == "job_1"

    with pytest.raises(TaskCodeRedeemConflictError):
        store.mark_used(code_id=record.code_id, job_id="job_2", used_at=now)


def test_delete_removes_record_and_index(tmp_path: Path) -> None:
    store = FileTaskCodeStore(data_dir=tmp_path)
    now = datetime(2026, 1, 1, 0, 0, 0, tzinfo=timezone.utc)
    record = store.issue_codes(
        tenant_id="default",
        count=1,
        expires_at=now + timedelta(days=1),
        now=now,
    )[0]

    store.delete(code_id=record.code_id)

    assert store.get(code_id=record.code_id) is None
    assert store.find_by_code(tenant_id="default", task_code=record.task_code) is None


def test_task_code_record_status_when_expires_at_is_naive_returns_expired() -> None:
    record = TaskCodeRecord(
        code_id="code_1",
        task_code="tc_demo",
        tenant_id="default",
        expires_at="2026-01-01T00:00:00",
    )
    now = datetime(2026, 1, 1, 0, 0, 0, tzinfo=timezone.utc)

    assert record.status(now=now) == "expired"

