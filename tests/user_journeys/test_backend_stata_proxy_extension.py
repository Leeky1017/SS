from __future__ import annotations

import asyncio
import json
import re

import pytest

from src.domain.models import JobConfirmation, JobInputs
from src.infra.plan_exceptions import PlanAlreadyFrozenError
from src.utils.job_workspace import resolve_job_dir


def _attach_primary_csv(*, store, jobs_dir, job_id: str, header: str) -> None:  # noqa: ANN001
    job = store.load(job_id)
    job.inputs = JobInputs(manifest_rel_path="inputs/manifest.json", fingerprint="fp-test")
    store.save(job)

    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job_id)
    assert job_dir is not None
    inputs_dir = job_dir / "inputs"
    inputs_dir.mkdir(parents=True, exist_ok=True)
    col_count = len([c for c in header.split(",") if c.strip() != ""])
    row = ",".join(["1" for _ in range(max(col_count, 1))])
    (inputs_dir / "primary.csv").write_text(header + "\n" + row + "\n", encoding="utf-8")
    (inputs_dir / "manifest.json").write_text(
        json.dumps(
            {
                "schema_version": 2,
                "datasets": [
                    {
                        "dataset_key": "primary",
                        "role": "primary_dataset",
                        "rel_path": "inputs/primary.csv",
                        "format": "csv",
                        "original_name": "primary.csv",
                    }
                ],
            },
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )


def test_plan_id_changes_when_confirmation_payload_changes(
    job_service,
    draft_service,
    plan_service,
):
    job = job_service.create_job(requirement="need a descriptive analysis")
    asyncio.run(draft_service.preview(job_id=job.job_id))

    plan_service.freeze_plan(
        job_id=job.job_id,
        confirmation=JobConfirmation(variable_corrections={"col_a": "col_b"}),
    )
    with pytest.raises(PlanAlreadyFrozenError):
        plan_service.freeze_plan(
            job_id=job.job_id,
            confirmation=JobConfirmation(variable_corrections={"col_a": "col_c"}),
        )


@pytest.mark.anyio
async def test_confirm_job_with_variable_corrections_rewrites_effective_dofile_tokens(
    journey_client,
    journey_worker_service,
    journey_store,
    journey_jobs_dir,
) -> None:
    created = await journey_client.post("/v1/jobs", json={"requirement": "hello"})
    assert created.status_code == 200
    job_id = created.json()["job_id"]

    preview = await journey_client.get(f"/v1/jobs/{job_id}/draft/preview")
    assert preview.status_code == 200

    _attach_primary_csv(
        store=journey_store,
        jobs_dir=journey_jobs_dir,
        job_id=job_id,
        header="col_b,col_a2",
    )
    job = journey_store.load(job_id)
    assert job.draft is not None
    job.draft = job.draft.model_copy(update={"outcome_var": "col_a", "treatment_var": "col_a2"})
    journey_store.save(job)

    confirmed = await journey_client.post(
        f"/v1/jobs/{job_id}/confirm",
        json={"confirmed": True, "variable_corrections": {"col_a": "col_b"}},
    )
    assert confirmed.status_code == 200
    assert confirmed.json()["status"] == "queued"

    assert journey_worker_service.process_next(worker_id="worker_test") is True

    artifacts = await journey_client.get(f"/v1/jobs/{job_id}/artifacts")
    assert artifacts.status_code == 200
    do_item = next(item for item in artifacts.json()["artifacts"] if item["kind"] == "stata.do")
    rel_path = do_item["rel_path"]
    downloaded = await journey_client.get(f"/v1/jobs/{job_id}/artifacts/{rel_path}")
    assert downloaded.status_code == 200
    do_text = downloaded.content.decode("utf-8", errors="ignore")

    assert re.search(r"(?<![A-Za-z0-9_])col_a(?![A-Za-z0-9_])", do_text) is None
    assert re.search(r"(?<![A-Za-z0-9_])col_b(?![A-Za-z0-9_])", do_text) is not None
    assert "col_a2" in do_text


@pytest.mark.anyio
async def test_confirm_job_when_column_missing_returns_contract_column_not_found(
    journey_client,
    journey_store,
    journey_jobs_dir,
) -> None:
    created = await journey_client.post("/v1/jobs", json={"requirement": "hello"})
    assert created.status_code == 200
    job_id = created.json()["job_id"]

    preview = await journey_client.get(f"/v1/jobs/{job_id}/draft/preview")
    assert preview.status_code == 200

    _attach_primary_csv(
        store=journey_store,
        jobs_dir=journey_jobs_dir,
        job_id=job_id,
        header="col_ok",
    )
    job = journey_store.load(job_id)
    assert job.draft is not None
    job.draft = job.draft.model_copy(update={"outcome_var": "col_a"})
    journey_store.save(job)

    confirmed = await journey_client.post(
        f"/v1/jobs/{job_id}/confirm",
        json={"confirmed": True, "variable_corrections": {"col_a": "col_missing"}},
    )
    assert confirmed.status_code == 400
    assert confirmed.json()["error_code"] == "CONTRACT_COLUMN_NOT_FOUND"
    assert "col_missing" in confirmed.json()["message"]

    got = await journey_client.get(f"/v1/jobs/{job_id}")
    assert got.status_code == 200
    assert got.json()["status"] != "queued"

