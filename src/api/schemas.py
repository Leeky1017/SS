from __future__ import annotations

from pydantic import BaseModel, Field


class CreateJobRequest(BaseModel):
    requirement: str | None = Field(default=None, description="User requirement text")


class CreateJobResponse(BaseModel):
    job_id: str
    status: str


class DraftPreviewResponse(BaseModel):
    job_id: str
    draft_text: str


class ConfirmJobRequest(BaseModel):
    confirmed: bool = True


class ConfirmJobResponse(BaseModel):
    job_id: str
    status: str
    scheduled_at: str | None = None


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
