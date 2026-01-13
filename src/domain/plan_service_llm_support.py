from __future__ import annotations

import asyncio
import json
from collections.abc import Mapping
from functools import partial

from src.domain.do_template_selection_evidence_payloads import selection_artifact_paths
from src.domain.job_workspace_store import JobWorkspaceStore
from src.domain.llm_client import LLMClient
from src.domain.models import ArtifactKind, Job
from src.domain.plan_generation_llm import PlanGenerationParseError
from src.domain.plan_generation_models import DataSchema, PlanConstraints, PlanGenerationInput
from src.infra.input_exceptions import InputPathUnsafeError


def selected_templates_for_plan_generation(
    *,
    tenant_id: str,
    job: Job,
    primary_template_id: str,
    workspace: JobWorkspaceStore,
) -> list[str]:
    selected: list[str] = [primary_template_id]
    _stage1_rel, _candidates_rel, stage2_rel = selection_artifact_paths()
    try:
        path = workspace.resolve_for_read(
            tenant_id=tenant_id,
            job_id=job.job_id,
            rel_path=stage2_rel,
        )
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (FileNotFoundError, OSError, json.JSONDecodeError, InputPathUnsafeError):
        return selected
    if not isinstance(raw, Mapping):
        return selected
    supplementary = raw.get("supplementary_template_ids", [])
    if not isinstance(supplementary, list):
        return selected
    for item in supplementary:
        if not isinstance(item, str) or item.strip() == "":
            continue
        if item not in selected:
            selected.append(item)
    return selected


def build_plan_generation_input(
    *,
    job: Job,
    requirement: str,
    selected_templates: list[str],
    max_steps: int,
) -> PlanGenerationInput:
    draft = job.draft
    columns = [] if draft is None else list(draft.column_candidates)
    detected_vars: dict[str, str | None] = {}
    has_panel_structure = False
    if draft is not None:
        payload = draft.model_dump(mode="json")
        for key in (
            "outcome_var",
            "treatment_var",
            "time_var",
            "entity_var",
            "cluster_var",
            "instrument_var",
        ):
            value = payload.get(key)
            if isinstance(value, str):
                detected_vars[key] = value.strip() if value.strip() != "" else None
            else:
                detected_vars[key] = None
        has_panel_structure = bool(
            detected_vars.get("time_var") is not None
            and detected_vars.get("entity_var") is not None
        )
    data_schema = DataSchema(
        columns=columns,
        n_rows=None,
        has_panel_structure=has_panel_structure,
        detected_vars=detected_vars,
    )
    constraints = PlanConstraints(
        max_steps=max_steps,
        required_outputs=[ArtifactKind.STATA_EXPORT_TABLE.value],
    )
    return PlanGenerationInput(
        job_id=job.job_id,
        requirement=requirement,
        draft=draft,
        selected_templates=selected_templates,
        data_schema=data_schema,
        constraints=constraints,
    )


def complete_text_sync(*, llm: LLMClient, job: Job, operation: str, prompt: str) -> str:
    try:
        import anyio

        return anyio.from_thread.run(
            partial(llm.complete_text, job=job, operation=operation, prompt=prompt),
        )
    except (RuntimeError, TypeError):
        pass

    try:
        asyncio.get_running_loop()
    except RuntimeError:
        return asyncio.run(llm.complete_text(job=job, operation=operation, prompt=prompt))
    raise PlanGenerationParseError(
        "LLM plan generation must run in a worker thread or sync context",
        raw_text="",
        error_code="PLAN_GEN_CALL_CONTEXT_INVALID",
    )
