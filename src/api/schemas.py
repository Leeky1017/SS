from __future__ import annotations

from pydantic import BaseModel, Field

from src.utils.json_types import JsonValue


class HealthCheck(BaseModel):
    ok: bool
    detail: str | None = None


class HealthResponse(BaseModel):
    status: str
    checks: dict[str, HealthCheck] = Field(default_factory=dict)
    checked_at: str


class CreateJobRequest(BaseModel):
    requirement: str | None = Field(default=None, description="User requirement text")


class CreateJobResponse(BaseModel):
    job_id: str
    trace_id: str | None = None
    status: str


class ConfirmJobRequest(BaseModel):
    confirmed: bool = True
    notes: str | None = None
    variable_corrections: dict[str, str] = Field(default_factory=dict)
    default_overrides: dict[str, JsonValue] = Field(default_factory=dict)


class ConfirmJobResponse(BaseModel):
    job_id: str
    status: str
    scheduled_at: str | None = None


class PlanStepResponse(BaseModel):
    step_id: str
    type: str
    params: dict[str, JsonValue] = Field(default_factory=dict)
    depends_on: list[str] = Field(default_factory=list)
    produces: list[str] = Field(default_factory=list)


class LLMPlanResponse(BaseModel):
    plan_version: int
    plan_id: str
    rel_path: str
    steps: list[PlanStepResponse] = Field(default_factory=list)


class FreezePlanRequest(BaseModel):
    notes: str | None = None


class FreezePlanResponse(BaseModel):
    job_id: str
    plan: LLMPlanResponse


class GetPlanResponse(BaseModel):
    job_id: str
    plan: LLMPlanResponse


class JobTimestamps(BaseModel):
    created_at: str
    scheduled_at: str | None = None


class DraftSummary(BaseModel):
    created_at: str
    text_chars: int


class ArtifactsSummary(BaseModel):
    total: int
    by_kind: dict[str, int] = Field(default_factory=dict)


class RunAttemptSummary(BaseModel):
    run_id: str
    attempt: int
    status: str
    started_at: str | None = None
    ended_at: str | None = None
    artifacts_count: int


class GetJobResponse(BaseModel):
    job_id: str
    trace_id: str | None = None
    status: str
    timestamps: JobTimestamps
    draft: DraftSummary | None = None
    artifacts: ArtifactsSummary
    latest_run: RunAttemptSummary | None = None


class ArtifactIndexItem(BaseModel):
    kind: str
    rel_path: str
    created_at: str | None = None
    meta: dict[str, str | int | float | bool | None] = Field(default_factory=dict)


class ArtifactsIndexResponse(BaseModel):
    job_id: str
    artifacts: list[ArtifactIndexItem] = Field(default_factory=list)


class RunJobResponse(BaseModel):
    job_id: str
    status: str
    scheduled_at: str | None = None


class InputsUploadResponse(BaseModel):
    job_id: str
    manifest_rel_path: str
    fingerprint: str


class InputsPreviewColumn(BaseModel):
    name: str
    inferred_type: str


class DraftPreviewDataSource(BaseModel):
    dataset_key: str
    role: str
    original_name: str
    format: str


class DraftPreviewResponse(BaseModel):
    job_id: str
    draft_text: str
    outcome_var: str | None = None
    treatment_var: str | None = None
    controls: list[str] = Field(default_factory=list)
    column_candidates: list[str] = Field(default_factory=list)
    variable_types: list[InputsPreviewColumn] = Field(default_factory=list)
    data_sources: list[DraftPreviewDataSource] = Field(default_factory=list)
    default_overrides: dict[str, JsonValue] = Field(default_factory=dict)


class InputsPreviewResponse(BaseModel):
    job_id: str
    row_count: int | None = None
    columns: list[InputsPreviewColumn] = Field(default_factory=list)
    sample_rows: list[dict[str, str | int | float | bool | None]] = Field(default_factory=list)

class TaskCodeRedeemRequest(BaseModel):
    task_code: str = Field(description="Task code to redeem", min_length=1)
    requirement: str = Field(description="Job requirement text (required field; may be empty)")


class TaskCodeRedeemResponse(BaseModel):
    job_id: str
    token: str
    expires_at: str
    is_idempotent: bool


class BundleFileDeclaration(BaseModel):
    filename: str
    size_bytes: int = Field(ge=0)
    role: str
    mime_type: str | None = None


class CreateBundleRequest(BaseModel):
    files: list[BundleFileDeclaration] = Field(default_factory=list)


class BundleFileResponse(BundleFileDeclaration):
    file_id: str


class BundleResponse(BaseModel):
    bundle_id: str
    job_id: str
    files: list[BundleFileResponse] = Field(default_factory=list)
