from __future__ import annotations

from pydantic import BaseModel, Field


class AdminLoginRequest(BaseModel):
    username: str
    password: str


class AdminLoginResponse(BaseModel):
    token: str
    token_id: str
    created_at: str


class AdminLogoutResponse(BaseModel):
    token_id: str
    revoked_at: str | None = None


class AdminTokenItem(BaseModel):
    token_id: str
    name: str
    created_at: str
    last_used_at: str | None = None
    revoked_at: str | None = None


class AdminTokenListResponse(BaseModel):
    tokens: list[AdminTokenItem] = Field(default_factory=list)


class AdminTokenCreateRequest(BaseModel):
    name: str = Field(default="personal", min_length=1, max_length=200)


class AdminTokenCreateResponse(BaseModel):
    token: str
    token_id: str
    created_at: str


class AdminTaskCodeItem(BaseModel):
    code_id: str
    task_code: str
    tenant_id: str
    created_at: str
    expires_at: str
    used_at: str | None = None
    job_id: str | None = None
    revoked_at: str | None = None
    status: str


class AdminTaskCodeCreateRequest(BaseModel):
    count: int = Field(default=1, ge=1, le=500)
    expires_in_days: int = Field(default=30, ge=1, le=3650)
    tenant_id: str = Field(default="default", min_length=1, max_length=200)


class AdminTaskCodeListResponse(BaseModel):
    task_codes: list[AdminTaskCodeItem] = Field(default_factory=list)


class AdminJobListItem(BaseModel):
    tenant_id: str
    job_id: str
    status: str
    created_at: str
    updated_at: str | None = None


class AdminJobListResponse(BaseModel):
    jobs: list[AdminJobListItem] = Field(default_factory=list)


class AdminArtifactItem(BaseModel):
    kind: str
    rel_path: str
    created_at: str | None = None
    meta: dict[str, str | int | float | bool | None] = Field(default_factory=dict)


class AdminRunAttemptItem(BaseModel):
    run_id: str
    attempt: int
    status: str
    started_at: str | None = None
    ended_at: str | None = None
    artifacts_count: int = 0


class AdminJobDetailResponse(BaseModel):
    tenant_id: str
    job_id: str
    status: str
    created_at: str
    scheduled_at: str | None = None
    requirement: str | None = None
    draft_text: str | None = None
    draft_created_at: str | None = None
    redeem_task_code: str | None = None
    auth_token: str | None = None
    auth_expires_at: str | None = None
    runs: list[AdminRunAttemptItem] = Field(default_factory=list)
    artifacts: list[AdminArtifactItem] = Field(default_factory=list)


class AdminJobRetryResponse(BaseModel):
    tenant_id: str
    job_id: str
    status: str
    scheduled_at: str | None = None


class AdminTenantListResponse(BaseModel):
    tenants: list[str] = Field(default_factory=list)


class AdminQueueDepth(BaseModel):
    queued: int
    claimed: int


class AdminWorkerStatus(BaseModel):
    worker_id: str
    active_claims: int
    latest_claimed_at: str | None = None
    latest_lease_expires_at: str | None = None


class AdminHealthCheckItem(BaseModel):
    ok: bool
    detail: str | None = None


class AdminHealthSummary(BaseModel):
    status: str
    checks: dict[str, AdminHealthCheckItem] = Field(default_factory=dict)


class AdminSystemStatusResponse(BaseModel):
    checked_at: str
    health: AdminHealthSummary
    queue: AdminQueueDepth
    workers: list[AdminWorkerStatus] = Field(default_factory=list)

