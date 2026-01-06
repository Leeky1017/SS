from __future__ import annotations

from enum import Enum

from pydantic import BaseModel, Field


class JobStatus(str, Enum):
    CREATED = "created"
    QUEUED = "queued"


class Draft(BaseModel):
    text: str
    created_at: str


class Job(BaseModel):
    job_id: str
    status: str = Field(default=JobStatus.CREATED.value)
    requirement: str | None = None
    created_at: str
    scheduled_at: str | None = None
    draft: Draft | None = None
