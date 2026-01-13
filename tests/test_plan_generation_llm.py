from __future__ import annotations

import json

import pytest

from src.domain.do_template_selection_evidence_payloads import selection_artifact_paths
from src.domain.llm_client import LLMClient
from src.domain.models import Draft, Job, JobConfirmation, JobStatus, PlanStepType
from src.domain.plan_generation_llm import (
    PlanGenerationParseError,
    build_plan_generation_prompt,
    parse_plan_generation_result,
)
from src.domain.plan_generation_models import DataSchema, PlanConstraints, PlanGenerationInput
from src.domain.plan_service import PlanService
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.infra.fs_do_template_catalog import FileSystemDoTemplateCatalog
from src.infra.fs_do_template_repository import FileSystemDoTemplateRepository
from src.utils.time import utc_now


class StaticLLMClient(LLMClient):
    def __init__(self, *, response_text: str) -> None:
        self._response_text = response_text

    async def complete_text(self, *, job: Job, operation: str, prompt: str) -> str:
        return self._response_text

    async def draft_preview(self, *, job: Job, prompt: str) -> Draft:
        return Draft(text="static", created_at=utc_now().isoformat())


def _plan_service_with_llm(
    *, store, jobs_dir, do_template_library_dir, llm: LLMClient
) -> PlanService:
    return PlanService(
        store=store,
        workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir),
        do_template_catalog=FileSystemDoTemplateCatalog(library_dir=do_template_library_dir),
        do_template_repo=FileSystemDoTemplateRepository(library_dir=do_template_library_dir),
        llm=llm,
    )


def test_build_plan_generation_prompt_with_valid_input_includes_required_sections() -> None:
    plan_input = PlanGenerationInput(
        job_id="job-1",
        requirement="Estimate effect of x on y.",
        draft=Draft(text="draft context", created_at="2026-01-01T00:00:00Z"),
        selected_templates=["T01", "TA14"],
        data_schema=DataSchema(
            columns=["y", "x"],
            n_rows=100,
            has_panel_structure=False,
            detected_vars={},
        ),
        constraints=PlanConstraints(max_steps=3, required_outputs=["stata.export.table"]),
    )

    prompt = build_plan_generation_prompt(plan_input=plan_input)

    assert "Constraint: steps <= 3." in prompt
    assert "REQUIREMENT:" in prompt
    assert "Estimate effect of x on y." in prompt
    assert '["T01", "TA14"]' in prompt


def test_parse_plan_generation_result_with_valid_json_returns_steps() -> None:
    payload = {
        "schema_version": 1,
        "steps": [
            {
                "step_id": "validate_data",
                "type": PlanStepType.DATA_VALIDATION.value,
                "purpose": "sanity check",
                "depends_on": [],
                "fallback_step_id": None,
                "params": {"template_id": "TA14"},
            }
        ],
    }
    steps = parse_plan_generation_result(
        text=json.dumps(payload),
        max_steps=3,
        selected_templates=["TA14"],
    )
    assert steps[0].step_id == "validate_data"
    assert steps[0].type == PlanStepType.DATA_VALIDATION


def test_parse_plan_generation_result_with_invalid_json_raises_parse_error() -> None:
    with pytest.raises(PlanGenerationParseError) as exc:
        parse_plan_generation_result(text="not-json", max_steps=3, selected_templates=["TA14"])
    assert exc.value.error_code == "PLAN_GEN_JSON_INVALID"


def test_parse_plan_generation_result_with_unsupported_step_type_raises_parse_error() -> None:
    payload = {"schema_version": 1, "steps": [{"step_id": "s1", "type": "unknown"}]}
    with pytest.raises(PlanGenerationParseError) as exc:
        parse_plan_generation_result(text=json.dumps(payload), max_steps=3, selected_templates=[])
    assert exc.value.error_code == "PLAN_GEN_UNSUPPORTED_STEP_TYPE"


def test_parse_plan_generation_result_with_unselected_template_id_raises_parse_error() -> None:
    payload = {
        "schema_version": 1,
        "steps": [
            {
                "step_id": "s1",
                "type": PlanStepType.DATA_VALIDATION.value,
                "params": {"template_id": "TA14"},
            }
        ],
    }
    with pytest.raises(PlanGenerationParseError) as exc:
        parse_plan_generation_result(
            text=json.dumps(payload),
            max_steps=3,
            selected_templates=["T01"],
        )
    assert exc.value.error_code == "PLAN_GEN_TEMPLATE_ID_UNSUPPORTED"


def test_freeze_plan_with_llm_when_llm_returns_invalid_json_falls_back_to_rule_plan(
    job_service, store, jobs_dir, do_template_library_dir
) -> None:
    job_id = job_service.create_job(requirement="hello").job_id
    job = store.load(job_id)
    job.status = JobStatus.DRAFT_READY
    store.save(job)

    plan_service = _plan_service_with_llm(
        store=store,
        jobs_dir=jobs_dir,
        do_template_library_dir=do_template_library_dir,
        llm=StaticLLMClient(response_text="not-json"),
    )
    plan = plan_service.freeze_plan(job_id=job_id, confirmation=JobConfirmation())

    assert plan.plan_source.value == "rule_fallback"
    assert plan.fallback_reason is not None

    workspace = FileJobWorkspaceStore(jobs_dir=jobs_dir)
    plan_path = workspace.resolve_for_read(job_id=job_id, rel_path="artifacts/plan.json")
    artifact = json.loads(plan_path.read_text(encoding="utf-8"))
    assert artifact["plan_source"] == "rule_fallback"
    assert "PLAN_GEN_JSON_INVALID" in artifact.get("fallback_reason", "")


def test_freeze_plan_with_llm_when_supplementary_templates_exist_allows_them(
    job_service, store, jobs_dir, do_template_library_dir
) -> None:
    job_id = job_service.create_job(requirement="hello").job_id
    job = store.load(job_id)
    job.status = JobStatus.DRAFT_READY
    job.selected_template_id = "T01"
    job.draft = Draft(text="draft", created_at=utc_now().isoformat(), outcome_var="y")
    store.save(job)

    _stage1_rel, _candidates_rel, stage2_rel = selection_artifact_paths()
    stage2_payload = {"schema_version": 1, "supplementary_template_ids": ["TA14"]}
    workspace = FileJobWorkspaceStore(jobs_dir=jobs_dir)
    workspace.write_bytes(
        job_id=job_id,
        rel_path=stage2_rel,
        data=(json.dumps(stage2_payload) + "\n").encode("utf-8"),
    )

    llm_payload = {
        "schema_version": 1,
        "steps": [
            {
                "step_id": "quality_check",
                "type": PlanStepType.DATA_VALIDATION.value,
                "purpose": "data quality",
                "depends_on": [],
                "fallback_step_id": None,
                "params": {"template_id": "TA14"},
            }
        ],
    }
    plan_service = _plan_service_with_llm(
        store=store,
        jobs_dir=jobs_dir,
        do_template_library_dir=do_template_library_dir,
        llm=StaticLLMClient(response_text=json.dumps(llm_payload)),
    )
    plan = plan_service.freeze_plan(job_id=job_id, confirmation=JobConfirmation())

    assert plan.plan_source.value == "llm"
    assert plan.steps[0].params.get("template_id") == "TA14"

    plan_path = workspace.resolve_for_read(job_id=job_id, rel_path="artifacts/plan.json")
    artifact = json.loads(plan_path.read_text(encoding="utf-8"))
    assert artifact["plan_source"] == "llm"
