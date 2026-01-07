from __future__ import annotations

import hashlib
import json
import logging
import re
from typing import cast

from src.domain.job_store import JobStore
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
from src.infra.exceptions import (
    JobStoreIOError,
    PlanAlreadyFrozenError,
    PlanArtifactsWriteError,
    PlanFreezeNotAllowedError,
)
from src.utils.json_types import JsonObject

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

    def __init__(self, *, store: JobStore):
        self._store = store

    def freeze_plan(self, *, job_id: str, confirmation: JobConfirmation) -> LLMPlan:
        logger.info("SS_PLAN_FREEZE_START", extra={"job_id": job_id})
        job = self._store.load(job_id)
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

        plan = self._build_plan(job=job, confirmation=confirmation, plan_id=expected_plan_id)
        self._write_plan_artifact(job_id=job_id, plan=plan)

        job.confirmation = confirmation
        job.llm_plan = plan
        self._ensure_plan_artifact_index(job=job, rel_path=plan.rel_path)
        self._store.save(job)
        logger.info("SS_PLAN_FROZEN", extra={"job_id": job_id, "plan_id": plan.plan_id})
        return plan

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
        requirement = job.requirement if job.requirement is not None else ""
        requirement_norm = _normalize_whitespace(requirement)
        requirement_fingerprint = _sha256_hex(requirement_norm)
        rel_path = "artifacts/plan.json"
        steps = [
            PlanStep(
                step_id="generate_do",
                type=PlanStepType.GENERATE_STATA_DO,
                params={
                    "template": "stub_descriptive_v1",
                    "requirement_fingerprint": requirement_fingerprint,
                },
                depends_on=[],
                produces=[ArtifactKind.STATA_DO],
            ),
            PlanStep(
                step_id="run_stata",
                type=PlanStepType.RUN_STATA,
                params={"timeout_seconds": 300},
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
        return LLMPlan(plan_id=plan_id, rel_path=rel_path, steps=steps)

    def _write_plan_artifact(self, *, job_id: str, plan: LLMPlan) -> None:
        try:
            self._store.write_artifact_json(
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
