// GENERATED FILE - DO NOT EDIT.
// Source: FastAPI OpenAPI → openapi-typescript@7.9.1.
// Run: scripts/contract_sync.sh generate

export interface components {
    schemas: {
        AdminArtifactItem: {
            created_at?: string | null;
            kind: string;
            meta?: {
                [key: string]: string | number | boolean | null;
            };
            rel_path: string;
        };
        AdminHealthCheckItem: {
            detail?: string | null;
            ok: boolean;
        };
        AdminHealthSummary: {
            checks?: {
                [key: string]: components["schemas"]["AdminHealthCheckItem"];
            };
            status: string;
        };
        AdminJobDetailResponse: {
            artifacts?: components["schemas"]["AdminArtifactItem"][];
            auth_expires_at?: string | null;
            auth_token?: string | null;
            created_at: string;
            draft_created_at?: string | null;
            draft_text?: string | null;
            job_id: string;
            redeem_task_code?: string | null;
            requirement?: string | null;
            runs?: components["schemas"]["AdminRunAttemptItem"][];
            scheduled_at?: string | null;
            status: string;
            tenant_id: string;
        };
        AdminJobListItem: {
            created_at: string;
            job_id: string;
            status: string;
            tenant_id: string;
            updated_at?: string | null;
        };
        AdminJobListResponse: {
            jobs?: components["schemas"]["AdminJobListItem"][];
        };
        AdminJobRetryResponse: {
            job_id: string;
            scheduled_at?: string | null;
            status: string;
            tenant_id: string;
        };
        AdminLoginRequest: {
            password: string;
            username: string;
        };
        AdminLoginResponse: {
            created_at: string;
            token: string;
            token_id: string;
        };
        AdminLogoutResponse: {
            revoked_at?: string | null;
            token_id: string;
        };
        AdminQueueDepth: {
            claimed: number;
            queued: number;
        };
        AdminRunAttemptItem: {
            artifacts_count: number;
            attempt: number;
            ended_at?: string | null;
            run_id: string;
            started_at?: string | null;
            status: string;
        };
        AdminSystemStatusResponse: {
            checked_at: string;
            health: components["schemas"]["AdminHealthSummary"];
            queue: components["schemas"]["AdminQueueDepth"];
            workers?: components["schemas"]["AdminWorkerStatus"][];
        };
        AdminTaskCodeCreateRequest: {
            count: number;
            expires_in_days: number;
            tenant_id: string;
        };
        AdminTaskCodeItem: {
            code_id: string;
            created_at: string;
            expires_at: string;
            job_id?: string | null;
            revoked_at?: string | null;
            status: string;
            task_code: string;
            tenant_id: string;
            used_at?: string | null;
        };
        AdminTaskCodeListResponse: {
            task_codes?: components["schemas"]["AdminTaskCodeItem"][];
        };
        AdminTenantListResponse: {
            tenants?: string[];
        };
        AdminTokenCreateRequest: {
            name: string;
        };
        AdminTokenCreateResponse: {
            created_at: string;
            token: string;
            token_id: string;
        };
        AdminTokenItem: {
            created_at: string;
            last_used_at?: string | null;
            name: string;
            revoked_at?: string | null;
            token_id: string;
        };
        AdminTokenListResponse: {
            tokens?: components["schemas"]["AdminTokenItem"][];
        };
        AdminWorkerStatus: {
            active_claims: number;
            latest_claimed_at?: string | null;
            latest_lease_expires_at?: string | null;
            worker_id: string;
        };
    };
    responses: never;
    parameters: never;
    requestBodies: never;
    headers: never;
    pathItems: never;
}
export type $defs = Record<string, never>;
export type operations = Record<string, never>;

export type AdminLoginRequest = components['schemas']['AdminLoginRequest'];
export type AdminLoginResponse = components['schemas']['AdminLoginResponse'];
export type AdminLogoutResponse = components['schemas']['AdminLogoutResponse'];
export type AdminTokenItem = components['schemas']['AdminTokenItem'];
export type AdminTokenListResponse = components['schemas']['AdminTokenListResponse'];
export type AdminTokenCreateRequest = components['schemas']['AdminTokenCreateRequest'];
export type AdminTokenCreateResponse = components['schemas']['AdminTokenCreateResponse'];
export type AdminTaskCodeItem = components['schemas']['AdminTaskCodeItem'];
export type AdminTaskCodeCreateRequest = components['schemas']['AdminTaskCodeCreateRequest'];
export type AdminTaskCodeListResponse = components['schemas']['AdminTaskCodeListResponse'];
export type AdminJobListItem = components['schemas']['AdminJobListItem'];
export type AdminJobListResponse = components['schemas']['AdminJobListResponse'];
export type AdminArtifactItem = components['schemas']['AdminArtifactItem'];
export type AdminRunAttemptItem = components['schemas']['AdminRunAttemptItem'];
export type AdminJobDetailResponse = components['schemas']['AdminJobDetailResponse'];
export type AdminJobRetryResponse = components['schemas']['AdminJobRetryResponse'];
export type AdminTenantListResponse = components['schemas']['AdminTenantListResponse'];
export type AdminSystemStatusResponse = components['schemas']['AdminSystemStatusResponse'];
