from __future__ import annotations

from enum import Enum
from pathlib import PurePosixPath

from pydantic import BaseModel, ConfigDict, Field, field_validator

from src.utils.job_workspace import is_safe_path_segment
from src.utils.json_types import JsonValue
from src.utils.tenancy import DEFAULT_TENANT_ID

JOB_SCHEMA_VERSION_V1 = 1
JOB_SCHEMA_VERSION_V2 = 2
JOB_SCHEMA_VERSION_V3 = 3
JOB_SCHEMA_VERSION_CURRENT = JOB_SCHEMA_VERSION_V3
SUPPORTED_JOB_SCHEMA_VERSIONS = [
    JOB_SCHEMA_VERSION_V1,
    JOB_SCHEMA_VERSION_V2,
    JOB_SCHEMA_VERSION_V3,
]
LLM_PLAN_VERSION_V1 = 1


class JobStatus(str, Enum):
    CREATED = "created"
    DRAFT_READY = "draft_ready"
    CONFIRMED = "confirmed"
    QUEUED = "queued"
    RUNNING = "running"
    SUCCEEDED = "succeeded"
    FAILED = "failed"


class ArtifactKind(str, Enum):
    INPUTS_MANIFEST = "inputs.manifest"
    INPUTS_DATASET = "inputs.dataset"
    LLM_PROMPT = "llm.prompt"
    LLM_RESPONSE = "llm.response"
    LLM_META = "llm.meta"
    PLAN_JSON = "plan.json"
    COMPOSITION_SUMMARY_JSON = "composition.summary.json"
    COMPOSITION_PRODUCT_DATASET = "composition.product.dataset"
    COMPOSITION_PRODUCT_TABLE = "composition.product.table"
    DO_TEMPLATE_SOURCE = "do_template.source"
    DO_TEMPLATE_META = "do_template.meta"
    DO_TEMPLATE_PARAMS = "do_template.params"
    DO_TEMPLATE_RUN_META_JSON = "do_template.run.meta.json"
    DO_TEMPLATE_SELECTION_STAGE1 = "do_template.selection.stage1"
    DO_TEMPLATE_SELECTION_CANDIDATES = "do_template.selection.candidates"
    DO_TEMPLATE_SELECTION_STAGE2 = "do_template.selection.stage2"
    STATA_DO = "stata.do"
    STATA_LOG = "stata.log"
    STATA_RESULT_LOG = "stata.result.log"
    RUN_STDOUT = "run.stdout"
    RUN_STDERR = "run.stderr"
    RUN_META_JSON = "run.meta.json"
    RUN_ERROR_JSON = "run.error.json"
    STATA_EXPORT_TABLE = "stata.export.table"
    STATA_EXPORT_FIGURE = "stata.export.figure"


def _is_safe_job_rel_path(value: str) -> bool:
    if value == "":
        return False
    if value.startswith("~"):
        return False
    if "\\" in value:
        return False
    path = PurePosixPath(value)
    if path.is_absolute():
        return False
    return ".." not in path.parts


def is_safe_job_rel_path(value: str) -> bool:
    return _is_safe_job_rel_path(value)


class ArtifactRef(BaseModel):
    model_config = ConfigDict(extra="allow")

    kind: ArtifactKind
    rel_path: str

    @field_validator("rel_path")
    @classmethod
    def rel_path_must_be_safe(cls, value: str) -> str:
        if not is_safe_job_rel_path(value):
            raise ValueError("rel_path must be job-relative and must not traverse")
        return value


class JobInputs(BaseModel):
    model_config = ConfigDict(extra="allow")

    manifest_rel_path: str | None = None
    fingerprint: str | None = None

    @field_validator("manifest_rel_path")
    @classmethod
    def manifest_rel_path_must_be_safe(cls, value: str | None) -> str | None:
        if value is None:
            return value
        if not is_safe_job_rel_path(value):
            raise ValueError("manifest_rel_path must be job-relative and must not traverse")
        return value


class DraftVariableType(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str
    inferred_type: str


class DraftDataSource(BaseModel):
    model_config = ConfigDict(extra="forbid")

    dataset_key: str
    role: str
    original_name: str
    format: str


class Draft(BaseModel):
    model_config = ConfigDict(extra="allow")

    text: str
    created_at: str
    outcome_var: str | None = None
    treatment_var: str | None = None
    controls: list[str] = Field(default_factory=list)
    column_candidates: list[str] = Field(default_factory=list)
    variable_types: list[DraftVariableType] = Field(default_factory=list)
    data_sources: list[DraftDataSource] = Field(default_factory=list)
    default_overrides: dict[str, JsonValue] = Field(default_factory=dict)


class JobConfirmation(BaseModel):
    model_config = ConfigDict(extra="forbid")

    requirement: str | None = None
    notes: str | None = None
    variable_corrections: dict[str, str] = Field(default_factory=dict)
    default_overrides: dict[str, JsonValue] = Field(default_factory=dict)


class PlanStepType(str, Enum):
    GENERATE_STATA_DO = "generate_stata_do"
    RUN_STATA = "run_stata"


class PlanStep(BaseModel):
    model_config = ConfigDict(extra="forbid")

    step_id: str
    type: PlanStepType
    params: dict[str, JsonValue] = Field(default_factory=dict)
    depends_on: list[str] = Field(default_factory=list)
    produces: list[ArtifactKind] = Field(default_factory=list)

    @field_validator("step_id")
    @classmethod
    def step_id_must_be_non_empty(cls, value: str) -> str:
        if value.strip() == "":
            raise ValueError("step_id must be non-empty")
        return value


class LLMPlan(BaseModel):
    model_config = ConfigDict(extra="forbid")

    plan_version: int = Field(default=LLM_PLAN_VERSION_V1)
    plan_id: str
    rel_path: str
    steps: list[PlanStep] = Field(default_factory=list)

    @field_validator("plan_version")
    @classmethod
    def plan_version_must_match_current(cls, value: int) -> int:
        if value != LLM_PLAN_VERSION_V1:
            raise ValueError(f"unsupported plan_version: {value}")
        return value

    @field_validator("rel_path")
    @classmethod
    def rel_path_must_be_safe(cls, value: str) -> str:
        if not is_safe_job_rel_path(value):
            raise ValueError("rel_path must be job-relative and must not traverse")
        return value

    @field_validator("steps")
    @classmethod
    def steps_must_have_unique_ids_and_valid_deps(cls, steps: list[PlanStep]) -> list[PlanStep]:
        ids = [step.step_id for step in steps]
        if len(ids) != len(set(ids)):
            raise ValueError("steps contain duplicate step_id")
        known = set(ids)
        for step in steps:
            for dep in step.depends_on:
                if dep not in known:
                    raise ValueError(f"unknown dependency: {dep}")
        return steps


class RunAttempt(BaseModel):
    model_config = ConfigDict(extra="allow")

    run_id: str
    attempt: int = 1
    status: str
    started_at: str | None = None
    ended_at: str | None = None
    artifacts: list[ArtifactRef] = Field(default_factory=list)


class Job(BaseModel):
    model_config = ConfigDict(extra="allow")

    schema_version: int
    version: int = Field(default=1, ge=1)
    tenant_id: str = Field(default=DEFAULT_TENANT_ID)
    job_id: str
    trace_id: str | None = None
    status: JobStatus = Field(default=JobStatus.CREATED)
    requirement: str | None = None
    confirmation: JobConfirmation | None = None
    created_at: str
    scheduled_at: str | None = None
    inputs: JobInputs | None = None
    draft: Draft | None = None
    llm_plan: LLMPlan | None = None
    runs: list[RunAttempt] = Field(default_factory=list)
    artifacts_index: list[ArtifactRef] = Field(default_factory=list)

    @field_validator("schema_version")
    @classmethod
    def schema_version_must_match_current(cls, value: int) -> int:
        if value != JOB_SCHEMA_VERSION_CURRENT:
            raise ValueError(f"unsupported schema_version: {value}")
        return value

    @field_validator("tenant_id")
    @classmethod
    def tenant_id_must_be_safe_segment(cls, value: str) -> str:
        if not is_safe_path_segment(value):
            raise ValueError("tenant_id must be a safe path segment")
        return value
