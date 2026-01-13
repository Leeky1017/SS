export type AdminLoginRequest = { username: string; password: string }
export type AdminLoginResponse = { token: string; token_id: string; created_at: string }
export type AdminLogoutResponse = { token_id: string; revoked_at: string | null }

export type AdminTokenItem = {
  token_id: string
  name: string
  created_at: string
  last_used_at: string | null
  revoked_at: string | null
}

export type AdminTokenListResponse = { tokens: AdminTokenItem[] }
export type AdminTokenCreateRequest = { name: string }
export type AdminTokenCreateResponse = { token: string; token_id: string; created_at: string }

export type AdminTaskCodeItem = {
  code_id: string
  task_code: string
  tenant_id: string
  created_at: string
  expires_at: string
  used_at: string | null
  job_id: string | null
  revoked_at: string | null
  status: string
}

export type AdminTaskCodeCreateRequest = {
  count: number
  expires_in_days: number
  tenant_id: string
}

export type AdminTaskCodeListResponse = { task_codes: AdminTaskCodeItem[] }

export type AdminJobListItem = {
  tenant_id: string
  job_id: string
  status: string
  created_at: string
  updated_at: string | null
}

export type AdminJobListResponse = { jobs: AdminJobListItem[] }

export type AdminArtifactItem = {
  kind: string
  rel_path: string
  created_at: string | null
  meta: Record<string, string | number | boolean | null>
}

export type AdminRunAttemptItem = {
  run_id: string
  attempt: number
  status: string
  started_at: string | null
  ended_at: string | null
  artifacts_count: number
}

export type AdminJobDetailResponse = {
  tenant_id: string
  job_id: string
  status: string
  created_at: string
  scheduled_at: string | null
  requirement: string | null
  draft_text: string | null
  draft_created_at: string | null
  redeem_task_code: string | null
  auth_token: string | null
  auth_expires_at: string | null
  runs: AdminRunAttemptItem[]
  artifacts: AdminArtifactItem[]
}

export type AdminJobRetryResponse = {
  tenant_id: string
  job_id: string
  status: string
  scheduled_at: string | null
}

export type AdminTenantListResponse = { tenants: string[] }

export type AdminSystemStatusResponse = {
  checked_at: string
  health: { status: string; checks: Record<string, { ok: boolean; detail: string | null }> }
  queue: { queued: number; claimed: number }
  workers: Array<{
    worker_id: string
    active_claims: number
    latest_claimed_at: string | null
    latest_lease_expires_at: string | null
  }>
}

