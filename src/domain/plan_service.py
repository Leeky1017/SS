from __future__ import annotations

import hashlib
import json
import logging
import re
from collections.abc import Mapping
from typing import cast

from src.domain.composition_plan import validate_composition_plan
from src.domain.job_store import JobStore
from src.domain.job_workspace_store import JobWorkspaceStore
from src.domain.models import (
    ArtifactKind,
    ArtifactRef,
    Job,
    JobConfirmation,
    JobStatus,
    LLMPlan,
    PlanStep,
    PlanStepType,
)
from src.domain.plan_contract import (
    analysis_spec_from_draft,
    apply_confirmation_effects,
    validate_contract_columns,
)
from src.domain.plan_routing import choose_composition_mode, extract_input_dataset_keys
from src.infra.exceptions import JobStoreIOError
from src.infra.input_exceptions import InputPathUnsafeError
from src.infra.plan_exceptions import (
    PlanAlreadyFrozenError,
    PlanArtifactsWriteError,
    PlanFreezeNotAllowedError,
    PlanMissingError,
)
from src.utils.json_types import JsonObject
from src.utils.tenancy import DEFAULT_TENANT_ID

logger = logging.getLogger(__name__)

_WHITESPACE_RE = re.compile(r"\s+")


def _normalize_whitespace(value: str) -> str:
    return _WHITESPACE_RE.sub(" ", value.strip())


def _sha256_hex(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8", errors="ignore")).hexdigest()


def _plan_id(
    *, job_id: str, inputs_fingerprint: str, requirement: str, confirmation: JsonObject
) -> str:
    canonical = json.dumps(
        {
            "v": 1,
            "job_id": job_id,
            "inputs_fingerprint": inputs_fingerprint,
            "requirement": requirement,
            "confirmation": confirmation,
        },
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    )
    return _sha256_hex(canonical)


class PlanService:
    """Plan service: freeze a schema-bound plan and persist it as an artifact."""

    def __init__(self, *, store: JobStore, workspace: JobWorkspaceStore):
        self._store = store
        self._workspace = workspace

    def freeze_plan(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
        confirmation: JobConfirmation,
    ) -> LLMPlan:
        logger.info("SS_PLAN_FREEZE_START", extra={"tenant_id": tenant_id, "job_id": job_id})
        job = self._store.load(tenant_id=tenant_id, job_id=job_id)
        confirmation = self._effective_confirmation(job=job, confirmation=confirmation)
        job, confirmation = apply_confirmation_effects(job=job, confirmation=confirmation)
        expected_plan_id = self._expected_plan_id(job=job, confirmation=confirmation)

        if job.llm_plan is not None:
            if job.llm_plan.plan_id != expected_plan_id:
                logger.warning(
                    "SS_PLAN_ALREADY_FROZEN_CONFLICT",
                    extra={
                        "job_id": job_id,
                        "existing_plan_id": job.llm_plan.plan_id,
                        "expected_plan_id": expected_plan_id,
                    },
                )
                raise PlanAlreadyFrozenError(job_id=job_id)
            logger.info(
                "SS_PLAN_FREEZE_IDEMPOTENT",
                extra={"job_id": job_id, "plan_id": job.llm_plan.plan_id},
            )
            return job.llm_plan

        if job.status not in {JobStatus.DRAFT_READY, JobStatus.CONFIRMED}:
            logger.warning(
                "SS_PLAN_FREEZE_NOT_ALLOWED",
                extra={"job_id": job_id, "status": job.status.value},
            )
            raise PlanFreezeNotAllowedError(job_id=job_id, status=job.status.value)

        validate_contract_columns(workspace=self._workspace, tenant_id=tenant_id, job=job)
        plan = self._build_plan(job=job, confirmation=confirmation, plan_id=expected_plan_id)
        self._write_plan_artifact(tenant_id=tenant_id, job_id=job_id, plan=plan)

        job.confirmation = confirmation
        job.llm_plan = plan
        self._ensure_plan_artifact_index(job=job, rel_path=plan.rel_path)
        self._store.save(tenant_id=tenant_id, job=job)
        logger.info(
            "SS_PLAN_FROZEN",
            extra={"tenant_id": tenant_id, "job_id": job_id, "plan_id": plan.plan_id},
        )
        return plan

    def get_frozen_plan(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
    ) -> LLMPlan:
        job = self._store.load(tenant_id=tenant_id, job_id=job_id)
        if job.llm_plan is None:
            raise PlanMissingError(job_id=job_id)
        return job.llm_plan

    def _effective_confirmation(
        self,
        *,
        job: Job,
        confirmation: JobConfirmation,
    ) -> JobConfirmation:
        updates: dict[str, object] = {}
        if confirmation.requirement is None:
            updates["requirement"] = job.requirement
        existing = job.confirmation
        if existing is not None:
            missing_corrections = len(confirmation.variable_corrections) == 0
            existing_corrections = len(existing.variable_corrections) > 0
            if missing_corrections and existing_corrections:
                updates["variable_corrections"] = existing.variable_corrections

            missing_overrides = len(confirmation.default_overrides) == 0
            existing_overrides = len(existing.default_overrides) > 0
            if missing_overrides and existing_overrides:
                updates["default_overrides"] = existing.default_overrides
        if len(updates) == 0:
            return confirmation
        return confirmation.model_copy(update=updates)

    def _expected_plan_id(self, *, job: Job, confirmation: JobConfirmation) -> str:
        inputs_fingerprint = ""
        if job.inputs is not None and job.inputs.fingerprint is not None:
            inputs_fingerprint = job.inputs.fingerprint

        requirement = job.requirement if job.requirement is not None else ""
        requirement_norm = _normalize_whitespace(requirement)
        confirmation_payload = cast(JsonObject, confirmation.model_dump(mode="json"))
        return _plan_id(
            job_id=job.job_id,
            inputs_fingerprint=inputs_fingerprint,
            requirement=requirement_norm,
            confirmation=confirmation_payload,
        )

    def _build_plan(self, *, job: Job, confirmation: JobConfirmation, plan_id: str) -> LLMPlan:
        requirement = confirmation.requirement if confirmation.requirement is not None else ""
        requirement_norm = _normalize_whitespace(requirement)
        requirement_fingerprint = _sha256_hex(requirement_norm)
        input_keys = self._known_input_keys(job=job)
        primary_key = "primary"
        if primary_key not in input_keys:
            primary_key = sorted(input_keys)[0]
        composition_mode = choose_composition_mode(
            requirement=requirement_norm,
            input_keys=input_keys,
        )
        rel_path = "artifacts/plan.json"
        steps = [
            PlanStep(
                step_id="generate_do",
                type=PlanStepType.GENERATE_STATA_DO,
                params={
                    "composition_mode": composition_mode.value,
                    "template_id": "stub_descriptive_v1",
                    "input_bindings": {"primary_dataset": f"input:{primary_key}"},
                    "products": [],
                    "requirement_fingerprint": requirement_fingerprint,
                    "analysis_spec": analysis_spec_from_draft(job=job),
                },
                depends_on=[],
                produces=[ArtifactKind.STATA_DO],
            ),
            PlanStep(
                step_id="run_stata",
                type=PlanStepType.RUN_STATA,
                params={
                    "composition_mode": composition_mode.value,
                    "timeout_seconds": 300,
                    "products": [{"product_id": "summary_table", "kind": "table"}],
                },
                depends_on=["generate_do"],
                produces=[
                    ArtifactKind.RUN_STDOUT,
                    ArtifactKind.RUN_STDERR,
                    ArtifactKind.STATA_LOG,
                    ArtifactKind.STATA_EXPORT_TABLE,
                    ArtifactKind.RUN_META_JSON,
                    ArtifactKind.RUN_ERROR_JSON,
                ],
            ),
        ]
        plan = LLMPlan(plan_id=plan_id, rel_path=rel_path, steps=steps)
        validate_composition_plan(plan=plan, known_input_keys=input_keys)
        return plan

    def _known_input_keys(self, *, job: Job) -> set[str]:
        default = {"primary"}
        if job.inputs is None:
            return default
        rel_path = job.inputs.manifest_rel_path
        if rel_path is None or rel_path.strip() == "":
            return default

        try:
            path = self._workspace.resolve_for_read(
                tenant_id=job.tenant_id,
                job_id=job.job_id,
                rel_path=rel_path,
            )
            raw = json.loads(path.read_text(encoding="utf-8"))
        except (FileNotFoundError, OSError, json.JSONDecodeError, InputPathUnsafeError) as e:
            logger.warning(
                "SS_PLAN_INPUTS_MANIFEST_READ_FAILED",
                extra={
                    "tenant_id": job.tenant_id,
                    "job_id": job.job_id,
                    "rel_path": rel_path,
                    "reason": str(e),
                },
            )
            return default
        if not isinstance(raw, Mapping):
            logger.warning(
                "SS_PLAN_INPUTS_MANIFEST_INVALID",
                extra={"tenant_id": job.tenant_id, "job_id": job.job_id, "rel_path": rel_path},
            )
            return default
        keys = extract_input_dataset_keys(manifest=raw)
        return default if len(keys) == 0 else keys

    def _write_plan_artifact(self, *, tenant_id: str, job_id: str, plan: LLMPlan) -> None:
        try:
            self._store.write_artifact_json(
                tenant_id=tenant_id,
                job_id=job_id,
                rel_path=plan.rel_path,
                payload=plan.model_dump(mode="json"),
            )
        except JobStoreIOError as e:
            logger.warning(
                "SS_PLAN_ARTIFACT_WRITE_FAILED",
                extra={"job_id": job_id, "error_code": e.error_code, "error_message": e.message},
            )
            raise PlanArtifactsWriteError(job_id=job_id) from e

    def _ensure_plan_artifact_index(self, *, job: Job, rel_path: str) -> None:
        for ref in job.artifacts_index:
            if ref.kind == ArtifactKind.PLAN_JSON and ref.rel_path == rel_path:
                return
        job.artifacts_index.append(ArtifactRef(kind=ArtifactKind.PLAN_JSON, rel_path=rel_path))
