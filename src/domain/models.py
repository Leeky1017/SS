from __future__ import annotations

from enum import Enum
from pathlib import PurePosixPath

from pydantic import BaseModel, ConfigDict, Field, field_validator

JOB_SCHEMA_VERSION_V1 = 1


class JobStatus(str, Enum):
    CREATED = "created"
    DRAFT_READY = "draft_ready"
    CONFIRMED = "confirmed"
    QUEUED = "queued"
    RUNNING = "running"
    SUCCEEDED = "succeeded"
    FAILED = "failed"


class ArtifactKind(str, Enum):
    LLM_PROMPT = "llm.prompt"
    LLM_RESPONSE = "llm.response"
    LLM_META = "llm.meta"
    PLAN_JSON = "plan.json"
    STATA_DO = "stata.do"
    STATA_LOG = "stata.log"
    RUN_STDOUT = "run.stdout"
    RUN_STDERR = "run.stderr"
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


class ArtifactRef(BaseModel):
    model_config = ConfigDict(extra="allow")

    kind: ArtifactKind
    rel_path: str

    @field_validator("rel_path")
    @classmethod
    def rel_path_must_be_safe(cls, value: str) -> str:
        if not _is_safe_job_rel_path(value):
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
        if not _is_safe_job_rel_path(value):
            raise ValueError("manifest_rel_path must be job-relative and must not traverse")
        return value


class Draft(BaseModel):
    model_config = ConfigDict(extra="allow")

    text: str
    created_at: str


class LLMPlan(BaseModel):
    model_config = ConfigDict(extra="allow")

    rel_path: str

    @field_validator("rel_path")
    @classmethod
    def rel_path_must_be_safe(cls, value: str) -> str:
        if not _is_safe_job_rel_path(value):
            raise ValueError("rel_path must be job-relative and must not traverse")
        return value


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
    job_id: str
    status: JobStatus = Field(default=JobStatus.CREATED)
    requirement: str | None = None
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
        if value != JOB_SCHEMA_VERSION_V1:
            raise ValueError(f"unsupported schema_version: {value}")
        return value
