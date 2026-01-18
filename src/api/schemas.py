from __future__ import annotations

from typing import Annotated, Literal

from pydantic import BaseModel, Field

from src.api.column_normalization_schemas import DraftColumnNameNormalization
from src.api.draft_column_candidate_schemas import DraftColumnCandidateV2
from src.api.inputs_preview_schemas import InputsPreviewColumn
from src.api.required_variable_schemas import DraftRequiredVariable
from src.utils.json_types import JsonScalar, JsonValue


class HealthCheck(BaseModel):
    ok: bool
    detail: str | None = None

class HealthResponse(BaseModel):
    status: str
    checks: dict[str, HealthCheck] = Field(default_factory=dict)
    checked_at: str

class ConfirmJobRequest(BaseModel):
    confirmed: bool
    notes: str | None = None
    output_formats: list[str] | None = None
    variable_corrections: dict[str, str]
    answers: dict[str, JsonValue]
    default_overrides: dict[str, JsonValue]
    expert_suggestions_feedback: dict[str, JsonValue]

class ConfirmJobResponse(BaseModel):
    job_id: str
    status: str
    scheduled_at: str | None = None
    message: str

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
    answers: dict[str, JsonValue] = Field(default_factory=dict)
    variable_corrections: dict[str, str] = Field(default_factory=dict)


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
    selected_template_id: str | None = None
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

class DraftPreviewDataSource(BaseModel):
    dataset_key: str
    role: str
    original_name: str
    format: str


class DraftDataQualityWarning(BaseModel):
    type: str
    severity: str
    message: str
    suggestion: str | None = None

class DraftStage1Option(BaseModel):
    option_id: str
    label: str
    value: JsonScalar

class DraftStage1Question(BaseModel):
    question_id: str
    question_text: str
    question_type: str
    options: list[DraftStage1Option] = Field(default_factory=list)
    priority: int = 0

class DraftOpenUnknown(BaseModel):
    field: str
    description: str
    impact: str
    blocking: bool | None = None
    candidates: list[str] = Field(default_factory=list)

class DraftPreviewResponse(BaseModel):
    job_id: str
    draft_text: str
    draft_id: str
    decision: Literal["auto_freeze", "require_confirm", "require_confirm_with_downgrade"]
    risk_score: float
    status: Literal["ready"] = "ready"
    outcome_var: str | None = None
    treatment_var: str | None = None
    controls: list[str] = Field(default_factory=list)
    column_candidates: list[str] = Field(default_factory=list)
    column_candidates_v2: list[DraftColumnCandidateV2] = Field(default_factory=list)
    column_name_normalizations: list[DraftColumnNameNormalization] = Field(default_factory=list)
    required_variables: list[DraftRequiredVariable] = Field(default_factory=list)
    data_quality_warnings: list[DraftDataQualityWarning] = Field(default_factory=list)
    stage1_questions: list[DraftStage1Question] = Field(default_factory=list)
    open_unknowns: list[DraftOpenUnknown] = Field(default_factory=list)
    variable_types: list[InputsPreviewColumn] = Field(default_factory=list)
    data_sources: list[DraftPreviewDataSource] = Field(default_factory=list)
    default_overrides: dict[str, JsonValue] = Field(default_factory=dict)

class DraftPreviewPendingResponse(BaseModel):
    status: Literal["pending"] = "pending"
    message: str
    retry_after_seconds: int
    retry_until: str

class DraftPatchRequest(BaseModel):
    field_updates: dict[str, JsonValue] = Field(default_factory=dict)

class DraftPatchResponse(BaseModel):
    status: Literal["patched"] = "patched"
    patched_fields: list[str] = Field(default_factory=list)
    remaining_unknowns_count: int
    open_unknowns: list[DraftOpenUnknown] = Field(default_factory=list)
    draft_preview: dict[str, JsonValue] = Field(default_factory=dict)

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
class CreateUploadSessionRequest(BaseModel):
    bundle_id: str
    file_id: str


class UploadSessionPartUrl(BaseModel):
    part_number: int
    url: str


class UploadSessionResponse(BaseModel):
    upload_session_id: str
    job_id: str
    file_id: str
    upload_strategy: Literal["direct", "multipart"]
    expires_at: str
    presigned_url: str | None = None
    part_size: int | None = None
    presigned_urls: list[UploadSessionPartUrl] = Field(default_factory=list)

class RefreshUploadUrlsRequest(BaseModel):
    part_numbers: list[int] | None = None

class RefreshUploadUrlsResponse(BaseModel):
    upload_session_id: str
    parts: list[UploadSessionPartUrl] = Field(default_factory=list)
    expires_at: str

class FinalizeUploadPart(BaseModel):
    part_number: int
    etag: str
    sha256: str | None = None


class FinalizeUploadRequest(BaseModel):
    parts: list[FinalizeUploadPart] = Field(default_factory=list)


class FinalizeUploadSuccess(BaseModel):
    success: Literal[True]
    status: str
    upload_session_id: str
    file_id: str
    sha256: str
    size_bytes: int


class FinalizeUploadFailure(BaseModel):
    success: Literal[False]
    retryable: bool
    error_code: str
    message: str


FinalizeUploadResponse = Annotated[
    FinalizeUploadSuccess | FinalizeUploadFailure,
    Field(discriminator="success"),
]
