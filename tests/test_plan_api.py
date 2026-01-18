from __future__ import annotations

import pytest

from src.api import deps
from src.domain.artifacts_service import ArtifactsService
from src.domain.job_query_service import JobQueryService
from src.domain.plan_service import PlanService
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.infra.fs_do_template_catalog import FileSystemDoTemplateCatalog
from src.infra.fs_do_template_repository import FileSystemDoTemplateRepository
from src.main import create_app
from tests.asgi_client import asgi_client
from tests.async_overrides import async_override

pytestmark = pytest.mark.anyio


def _test_app(*, job_service, draft_service, store, jobs_dir, do_template_library_dir):  # noqa: ANN001
    app = create_app()
    app.dependency_overrides[deps.get_job_service] = async_override(job_service)
    app.dependency_overrides[deps.get_job_query_service] = async_override(
        JobQueryService(store=store)
    )
    app.dependency_overrides[deps.get_draft_service] = async_override(draft_service)
    app.dependency_overrides[deps.get_artifacts_service] = async_override(
        ArtifactsService(store=store, jobs_dir=jobs_dir)
    )
    app.dependency_overrides[deps.get_plan_service] = async_override(
        PlanService(
            store=store,
            workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir),
            do_template_catalog=FileSystemDoTemplateCatalog(library_dir=do_template_library_dir),
            do_template_repo=FileSystemDoTemplateRepository(library_dir=do_template_library_dir),
        )
    )
    return app


async def test_freeze_plan_when_job_not_ready_returns_409(
    job_service, draft_service, store, jobs_dir, do_template_library_dir
) -> None:
    app = _test_app(
        job_service=job_service,
        draft_service=draft_service,
        store=store,
        jobs_dir=jobs_dir,
        do_template_library_dir=do_template_library_dir,
    )
    async with asgi_client(app=app) as client:
        job_id = job_service.create_job(requirement="hello").job_id

        response = await client.post(f"/v1/jobs/{job_id}/plan/freeze", json={})

    assert response.status_code == 409
    assert response.json()["error_code"] == "PLAN_FREEZE_NOT_ALLOWED"


async def test_freeze_plan_then_get_plan_returns_plan(
    job_service, draft_service, store, jobs_dir, do_template_library_dir
) -> None:
    app = _test_app(
        job_service=job_service,
        draft_service=draft_service,
        store=store,
        jobs_dir=jobs_dir,
        do_template_library_dir=do_template_library_dir,
    )
    async with asgi_client(app=app) as client:
        job_id = job_service.create_job(requirement="hello").job_id

        preview = await client.get(f"/v1/jobs/{job_id}/draft/preview")
        assert preview.status_code == 200

        frozen = await client.post(f"/v1/jobs/{job_id}/plan/freeze", json={})
        assert frozen.status_code == 200
        assert frozen.json()["plan"]["rel_path"] == "artifacts/plan.json"

        got = await client.get(f"/v1/jobs/{job_id}/plan")
        assert got.status_code == 200
        assert got.json()["plan"]["plan_id"] == frozen.json()["plan"]["plan_id"]


async def test_confirm_auto_freezes_plan_before_queueing(
    job_service, draft_service, store, jobs_dir, do_template_library_dir
) -> None:
    app = _test_app(
        job_service=job_service,
        draft_service=draft_service,
        store=store,
        jobs_dir=jobs_dir,
        do_template_library_dir=do_template_library_dir,
    )
    async with asgi_client(app=app) as client:
        job_id = job_service.create_job(requirement="hello").job_id

        preview = await client.get(f"/v1/jobs/{job_id}/draft/preview")
        assert preview.status_code == 200

        confirmed = await client.post(
            f"/v1/jobs/{job_id}/confirm",
            json={
                "confirmed": True,
                "variable_corrections": {},
                "answers": {},
                "default_overrides": {},
                "expert_suggestions_feedback": {},
            },
        )
        assert confirmed.status_code == 200
        assert confirmed.json()["status"] == "queued"

        got = await client.get(f"/v1/jobs/{job_id}/plan")
        assert got.status_code == 200
        assert got.json()["plan"]["rel_path"] == "artifacts/plan.json"


async def test_freeze_plan_when_called_twice_is_idempotent(
    job_service, draft_service, store, jobs_dir, do_template_library_dir
) -> None:
    app = _test_app(
        job_service=job_service,
        draft_service=draft_service,
        store=store,
        jobs_dir=jobs_dir,
        do_template_library_dir=do_template_library_dir,
    )
    async with asgi_client(app=app) as client:
        job_id = job_service.create_job(requirement="hello").job_id

        preview = await client.get(f"/v1/jobs/{job_id}/draft/preview")
        assert preview.status_code == 200

        first = await client.post(f"/v1/jobs/{job_id}/plan/freeze", json={})
        second = await client.post(f"/v1/jobs/{job_id}/plan/freeze", json={})
        assert first.status_code == 200
        assert second.status_code == 200
        assert second.json()["plan"]["plan_id"] == first.json()["plan"]["plan_id"]

        artifacts = await client.get(f"/v1/jobs/{job_id}/artifacts")
        assert artifacts.status_code == 200
        plan_entries = [a for a in artifacts.json()["artifacts"] if a["kind"] == "plan.json"]
        assert len(plan_entries) == 1
        assert plan_entries[0]["rel_path"] == "artifacts/plan.json"


async def test_freeze_plan_when_notes_change_returns_conflict(
    job_service, draft_service, store, jobs_dir, do_template_library_dir
) -> None:
    app = _test_app(
        job_service=job_service,
        draft_service=draft_service,
        store=store,
        jobs_dir=jobs_dir,
        do_template_library_dir=do_template_library_dir,
    )
    async with asgi_client(app=app) as client:
        job_id = job_service.create_job(requirement="hello").job_id

        preview = await client.get(f"/v1/jobs/{job_id}/draft/preview")
        assert preview.status_code == 200

        first = await client.post(f"/v1/jobs/{job_id}/plan/freeze", json={"notes": "v1"})
        assert first.status_code == 200

        conflict = await client.post(f"/v1/jobs/{job_id}/plan/freeze", json={"notes": "v2"})
        assert conflict.status_code == 409
        assert conflict.json()["error_code"] == "PLAN_ALREADY_FROZEN_CONFLICT"


async def test_freeze_plan_when_required_template_params_missing_returns_structured_error(
    job_service, draft_service, store, jobs_dir, do_template_library_dir
) -> None:
    app = _test_app(
        job_service=job_service,
        draft_service=draft_service,
        store=store,
        jobs_dir=jobs_dir,
        do_template_library_dir=do_template_library_dir,
    )
    async with asgi_client(app=app) as client:
        job_id = job_service.create_job(requirement="hello").job_id

        preview = await client.get(f"/v1/jobs/{job_id}/draft/preview")
        assert preview.status_code == 200

        loaded = store.load(job_id)
        loaded.selected_template_id = "T01"
        store.save(loaded)

        missing = await client.post(f"/v1/jobs/{job_id}/plan/freeze", json={})

        assert missing.status_code == 400
        payload = missing.json()
        assert payload["error_code"] == "PLAN_FREEZE_MISSING_REQUIRED"
        assert "__NUMERIC_VARS__" in payload.get("missing_params", [])
        assert isinstance(payload.get("next_actions"), list)
        assert isinstance(payload.get("missing_fields_detail"), list)
        assert isinstance(payload.get("missing_params_detail"), list)
        assert isinstance(payload.get("action"), str)
        assert any(
            item.get("param") == "__NUMERIC_VARS__"
            for item in payload.get("missing_params_detail", [])
        )
        assert any(item.get("action") == "patch_draft" for item in payload.get("next_actions", []))

        loaded = store.load(job_id)
        assert loaded.draft is not None
        loaded.draft = loaded.draft.model_copy(update={"outcome_var": "x"})
        store.save(loaded)

        fixed = await client.post(f"/v1/jobs/{job_id}/plan/freeze", json={})
        assert fixed.status_code == 200


async def test_freeze_plan_when_template_requires_id_time_accepts_variable_corrections(
    job_service, draft_service, store, jobs_dir, do_template_library_dir
) -> None:
    app = _test_app(
        job_service=job_service,
        draft_service=draft_service,
        store=store,
        jobs_dir=jobs_dir,
        do_template_library_dir=do_template_library_dir,
    )
    async with asgi_client(app=app) as client:
        job_id = job_service.create_job(requirement="hello").job_id

        preview = await client.get(f"/v1/jobs/{job_id}/draft/preview")
        assert preview.status_code == 200

        loaded = store.load(job_id)
        loaded.selected_template_id = "T30"
        store.save(loaded)

        missing = await client.post(f"/v1/jobs/{job_id}/plan/freeze", json={})
        assert missing.status_code == 400
        payload = missing.json()
        assert payload["error_code"] == "PLAN_FREEZE_MISSING_REQUIRED"
        assert "__ID_VAR__" in payload.get("missing_params", [])
        assert "__TIME_VAR__" in payload.get("missing_params", [])
        assert any(
            item.get("param") == "__ID_VAR__" for item in payload.get("missing_params_detail", [])
        )
        assert any(
            item.get("param") == "__TIME_VAR__" for item in payload.get("missing_params_detail", [])
        )
        assert any(
            item.get("action") == "provide_variable_corrections"
            for item in payload.get("next_actions", [])
        )

        fixed = await client.post(
            f"/v1/jobs/{job_id}/plan/freeze",
            json={
                "variable_corrections": {"__ID_VAR__": "id", "__TIME_VAR__": "year"},
            },
        )
        assert fixed.status_code == 200
        template_params = fixed.json()["plan"]["steps"][0]["params"]["template_params"]
        assert template_params["__ID_VAR__"] == "id"
        assert template_params["__TIME_VAR__"] == "year"
