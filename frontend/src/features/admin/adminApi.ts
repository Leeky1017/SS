import { toNetworkError, toParseError } from '../../api/errors'
import type { ApiResult } from '../../api/errors'
import {
  encodePathPreservingSlashes,
  readErrorCode,
  requestId,
  safeJson,
} from '../../api/utils'
import { toUserErrorMessage } from '../../utils/errorCodes'
import { clearAdminToken, loadAdminToken } from './adminStorage'
import type {
  AdminJobDetailResponse,
  AdminJobListResponse,
  AdminJobRetryResponse,
  AdminLoginRequest,
  AdminLoginResponse,
  AdminLogoutResponse,
  AdminSystemStatusResponse,
  AdminTaskCodeCreateRequest,
  AdminTaskCodeItem,
  AdminTaskCodeListResponse,
  AdminTenantListResponse,
  AdminTokenCreateRequest,
  AdminTokenCreateResponse,
  AdminTokenItem,
  AdminTokenListResponse,
} from './adminApiTypes'

type AdminApiClientOptions = { baseUrl?: string }

export class AdminApiClient {
  private readonly baseUrl: string
  public lastRequestId: string | null = null

  constructor(options: AdminApiClientOptions = {}) {
    const raw = options.baseUrl?.trim()
    this.baseUrl = raw !== undefined && raw !== '' ? raw : '/api/admin'
  }

  public async login(payload: AdminLoginRequest): Promise<ApiResult<AdminLoginResponse>> {
    return await this.postJson<AdminLoginResponse>('/auth/login', payload, { auth: false })
  }

  public async logout(): Promise<ApiResult<AdminLogoutResponse>> {
    return await this.postJson<AdminLogoutResponse>('/auth/logout', {}, { auth: true })
  }

  public async listTenants(): Promise<ApiResult<AdminTenantListResponse>> {
    return await this.getJson<AdminTenantListResponse>('/tenants', { auth: true })
  }

  public async getSystemStatus(): Promise<ApiResult<AdminSystemStatusResponse>> {
    return await this.getJson<AdminSystemStatusResponse>('/system/status', { auth: true })
  }

  public async listTokens(): Promise<ApiResult<AdminTokenListResponse>> {
    return await this.getJson<AdminTokenListResponse>('/tokens', { auth: true })
  }

  public async createToken(payload: AdminTokenCreateRequest): Promise<ApiResult<AdminTokenCreateResponse>> {
    return await this.postJson<AdminTokenCreateResponse>('/tokens', payload, { auth: true })
  }

  public async revokeToken(tokenId: string): Promise<ApiResult<AdminTokenItem>> {
    return await this.postJson<AdminTokenItem>(`/tokens/${encodeURIComponent(tokenId)}/revoke`, {}, { auth: true })
  }

  public async deleteToken(tokenId: string): Promise<ApiResult<null>> {
    return await this.request<null>({
      path: `/tokens/${encodeURIComponent(tokenId)}`,
      method: 'DELETE',
      auth: true,
      tenantId: null,
      responseType: 'json',
    })
  }

  public async createTaskCodes(payload: AdminTaskCodeCreateRequest): Promise<ApiResult<AdminTaskCodeListResponse>> {
    return await this.postJson<AdminTaskCodeListResponse>('/task-codes', payload, { auth: true })
  }

  public async listTaskCodes(args: {
    tenantId: string | null
    status: string | null
  }): Promise<ApiResult<AdminTaskCodeListResponse>> {
    const q = new URLSearchParams()
    if (args.tenantId !== null && args.tenantId.trim() !== '') q.set('tenant_id', args.tenantId)
    if (args.status !== null && args.status.trim() !== '') q.set('status', args.status)
    const suffix = q.toString()
    return await this.getJson<AdminTaskCodeListResponse>(`/task-codes${suffix === '' ? '' : `?${suffix}`}`, {
      auth: true,
    })
  }

  public async revokeTaskCode(codeId: string): Promise<ApiResult<AdminTaskCodeItem>> {
    return await this.postJson<AdminTaskCodeItem>(`/task-codes/${encodeURIComponent(codeId)}/revoke`, {}, { auth: true })
  }

  public async deleteTaskCode(codeId: string): Promise<ApiResult<null>> {
    return await this.request<null>({
      path: `/task-codes/${encodeURIComponent(codeId)}`,
      method: 'DELETE',
      auth: true,
      tenantId: null,
      responseType: 'json',
    })
  }

  public async listJobs(args: {
    tenantId: string | null
    status: string | null
  }): Promise<ApiResult<AdminJobListResponse>> {
    const q = new URLSearchParams()
    if (args.tenantId !== null && args.tenantId.trim() !== '') q.set('tenant_id', args.tenantId)
    if (args.status !== null && args.status.trim() !== '') q.set('status', args.status)
    const suffix = q.toString()
    return await this.getJson<AdminJobListResponse>(`/jobs${suffix === '' ? '' : `?${suffix}`}`, { auth: true })
  }

  public async getJobDetail(jobId: string, tenantId: string): Promise<ApiResult<AdminJobDetailResponse>> {
    return await this.getJson<AdminJobDetailResponse>(`/jobs/${encodeURIComponent(jobId)}`, { auth: true, tenantId })
  }

  public async retryJob(jobId: string, tenantId: string): Promise<ApiResult<AdminJobRetryResponse>> {
    return await this.postJson<AdminJobRetryResponse>(`/jobs/${encodeURIComponent(jobId)}/retry`, {}, { auth: true, tenantId })
  }

  public async downloadJobArtifact(jobId: string, relPath: string, tenantId: string): Promise<ApiResult<Blob>> {
    const encoded = encodePathPreservingSlashes(relPath)
    return await this.request<Blob>({
      path: `/jobs/${encodeURIComponent(jobId)}/artifacts/${encoded}`,
      method: 'GET',
      auth: true,
      tenantId,
      responseType: 'blob',
    })
  }

  private async getJson<T>(path: string, opts: { auth: boolean; tenantId?: string }): Promise<ApiResult<T>> {
    return await this.request<T>({
      path,
      method: 'GET',
      auth: opts.auth,
      tenantId: opts.tenantId ?? null,
      responseType: 'json',
    })
  }

  private async postJson<T>(
    path: string,
    payload: unknown,
    opts: { auth: boolean; tenantId?: string },
  ): Promise<ApiResult<T>> {
    return await this.request<T>({
      path,
      method: 'POST',
      auth: opts.auth,
      tenantId: opts.tenantId ?? null,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
      responseType: 'json',
    })
  }

  private buildHeaders(args: { auth: boolean; tenantId: string | null }, rid: string): Headers {
    const headers = new Headers()
    headers.set('X-SS-Request-Id', rid)
    if (args.tenantId !== null && args.tenantId.trim() !== '') headers.set('X-SS-Tenant-ID', args.tenantId)
    if (args.auth) this.attachAuth(headers)
    return headers
  }

  private attachAuth(headers: Headers): void {
    const token = loadAdminToken()
    if (token !== null && token.trim() !== '') headers.set('Authorization', `Bearer ${token}`)
  }

  private async request<T>(args: {
    path: string
    method: 'GET' | 'POST' | 'DELETE'
    auth: boolean
    tenantId: string | null
    body?: BodyInit
    headers?: Record<string, string>
    responseType: 'json' | 'blob'
  }): Promise<ApiResult<T>> {
    const rid = requestId()
    this.lastRequestId = rid

    const headers = this.buildHeaders(args, rid)
    if (args.headers !== undefined) {
      for (const [key, value] of Object.entries(args.headers)) headers.set(key, value)
    }

    let response: Response
    try {
      response = await fetch(`${this.baseUrl}${args.path}`, { method: args.method, headers, body: args.body })
    } catch (err) {
      return toNetworkError(rid, err)
    }

    const responseRequestId = response.headers.get('X-SS-Request-Id')
    const effectiveRequestId =
      responseRequestId !== null && responseRequestId.trim() !== '' ? responseRequestId : rid

    if (response.status === 401 || response.status === 403) clearAdminToken()

    if (!response.ok) return await this.httpError(response, effectiveRequestId)

    if (args.responseType === 'blob') {
      const blob = await response.blob()
      return { ok: true, value: blob as T, requestId: effectiveRequestId }
    }

    try {
      const json = (await safeJson(response)) as T
      return { ok: true, value: json, requestId: effectiveRequestId }
    } catch (err) {
      return toParseError(effectiveRequestId, err)
    }
  }

  private async httpError(response: Response, requestId: string): Promise<ApiResult<never>> {
    let details: unknown = null
    try {
      details = await safeJson(response)
    } catch (err) {
      details = err
    }
    const kind = response.status === 401 ? 'unauthorized' : response.status === 403 ? 'forbidden' : 'http'
    const internalCode = readErrorCode(details)
    const message = toUserErrorMessage({ internalCode, kind, status: response.status })
    return { ok: false, error: { kind, status: response.status, message, requestId, details, internalCode, action: 'retry' } }
  }
}
