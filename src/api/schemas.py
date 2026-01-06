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
