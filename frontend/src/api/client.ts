import { toNetworkError, toParseError } from './errors'
import type { ApiResult } from './errors'
import type {
  ArtifactsIndexResponse,
  ConfirmJobRequest,
  ConfirmJobResponse,
  CreateJobRequest,
  CreateJobResponse,
  DraftPatchRequest,
  DraftPatchResponse,
  DraftPreviewResponse,
  FreezePlanRequest,
  FreezePlanResponse,
  GetJobResponse,
  GetPlanResponse,
  InputsPreviewResponse,
  InputsUploadResponse,
  RedeemTaskCodeRequest,
  RedeemTaskCodeResponse,
  RunJobResponse,
} from './types'
import { encodePathPreservingSlashes, readErrorMessage, requestId, resolveBaseUrl, safeJson } from './utils'
import { clearAuthToken, getAuthToken } from '../state/storage'

type ApiClientOptions = { baseUrl?: string }

function isDevMockEnabled(): boolean {
  return import.meta.env.DEV && (import.meta.env.VITE_API_MOCK as string | undefined) !== '0'
}

function requireTaskCode(): boolean {
  return (import.meta.env.VITE_REQUIRE_TASK_CODE as string | undefined) === '1'
}

function canFallbackToCreateJob(): boolean {
  return import.meta.env.DEV && !requireTaskCode()
}

export class ApiClient {
  private readonly baseUrl: string
  public lastRequestId: string | null = null

  constructor(options: ApiClientOptions = {}) {
    this.baseUrl = resolveBaseUrl(options.baseUrl)
  }

  public isDevMockEnabled(): boolean {
    return isDevMockEnabled()
  }

  public canFallbackToCreateJob(): boolean {
    return canFallbackToCreateJob()
  }

  public requireTaskCode(): boolean {
    return requireTaskCode()
  }

  public async redeemTaskCode(payload: RedeemTaskCodeRequest): Promise<ApiResult<RedeemTaskCodeResponse>> {
    if (this.isDevMockEnabled()) {
      const suffix = (payload.task_code || payload.requirement).slice(0, 12).replaceAll(/\s+/g, '-')
      const token = `token_mock_${suffix}_${Date.now().toString(16)}`
      return { ok: true, value: { job_id: `job_mock_${suffix}`, token }, requestId: 'mock' }
    }
    return await this.postJson<RedeemTaskCodeResponse>('/task-codes/redeem', payload, null)
  }

  public async createJob(payload: CreateJobRequest): Promise<ApiResult<CreateJobResponse>> {
    return await this.postJson<CreateJobResponse>('/jobs', payload, null)
  }

  public async uploadInputs(
    jobId: string,
    files: File[],
    options: { role?: string[]; filename?: string[] } = {},
  ): Promise<ApiResult<InputsUploadResponse>> {
    const form = new FormData()
    for (const file of files) {
      form.append('file', file)
    }
    if (options.role !== undefined) {
      for (const role of options.role) {
        form.append('role', role)
      }
    }
    if (options.filename !== undefined) {
      for (const filename of options.filename) {
        form.append('filename', filename)
      }
    }
    return await this.request<InputsUploadResponse>({
      path: `/jobs/${jobId}/inputs/upload`,
      method: 'POST',
      jobId,
      body: form,
    })
  }

  public async previewInputs(jobId: string): Promise<ApiResult<InputsPreviewResponse>> {
    return await this.getJson<InputsPreviewResponse>(`/jobs/${jobId}/inputs/preview`, jobId)
  }

  public async previewDraft(jobId: string): Promise<ApiResult<DraftPreviewResponse>> {
    return await this.getJson<DraftPreviewResponse>(`/jobs/${jobId}/draft/preview`, jobId)
  }

  public async patchDraft(jobId: string, payload: DraftPatchRequest): Promise<ApiResult<DraftPatchResponse>> {
    return await this.postJson<DraftPatchResponse>(`/jobs/${jobId}/draft/patch`, payload, jobId)
  }

  public async confirmJob(jobId: string, payload: ConfirmJobRequest): Promise<ApiResult<ConfirmJobResponse>> {
    return await this.postJson<ConfirmJobResponse>(`/jobs/${jobId}/confirm`, payload, jobId)
  }

  public async getJob(jobId: string): Promise<ApiResult<GetJobResponse>> {
    return await this.getJson<GetJobResponse>(`/jobs/${jobId}`, jobId)
  }

  public async listArtifacts(jobId: string): Promise<ApiResult<ArtifactsIndexResponse>> {
    return await this.getJson<ArtifactsIndexResponse>(`/jobs/${jobId}/artifacts`, jobId)
  }

  public async downloadArtifact(jobId: string, artifactId: string): Promise<ApiResult<Blob>> {
    const encoded = encodePathPreservingSlashes(artifactId)
    return await this.request<Blob>({
      path: `/jobs/${jobId}/artifacts/${encoded}`,
      method: 'GET',
      jobId,
      responseType: 'blob',
    })
  }

  public async runJob(jobId: string): Promise<ApiResult<RunJobResponse>> {
    return await this.postJson<RunJobResponse>(`/jobs/${jobId}/run`, {}, jobId)
  }

  public async freezePlan(jobId: string, payload: FreezePlanRequest): Promise<ApiResult<FreezePlanResponse>> {
    return await this.postJson<FreezePlanResponse>(`/jobs/${jobId}/plan/freeze`, payload, jobId)
  }

  public async getPlan(jobId: string): Promise<ApiResult<GetPlanResponse>> {
    return await this.getJson<GetPlanResponse>(`/jobs/${jobId}/plan`, jobId)
  }

  private async getJson<T>(path: string, jobId: string | null): Promise<ApiResult<T>> {
    return await this.request<T>({ path, method: 'GET', jobId })
  }

  private async postJson<T>(path: string, payload: unknown, jobId: string | null): Promise<ApiResult<T>> {
    return await this.request<T>({
      path,
      method: 'POST',
      jobId,
      body: JSON.stringify(payload),
      headers: { 'Content-Type': 'application/json' },
    })
  }

  private async request<T>(args: {
    path: string
    method: 'GET' | 'POST'
    jobId: string | null
    body?: BodyInit
    headers?: Record<string, string>
    responseType?: 'json' | 'blob'
  }): Promise<ApiResult<T>> {
    const rid = requestId()
    this.lastRequestId = rid

    const headers = this.buildHeaders(args, rid)
    const fetched = await this.fetchResponse(args, headers, rid)
    if (!fetched.ok) return fetched

    const { response, effectiveRequestId } = fetched.value
    const authError = this.authErrorIfAny(response.status, args.jobId, effectiveRequestId)
    if (authError !== null) return authError

    if (!response.ok) return await this.httpError(response, effectiveRequestId)
    return await this.okResult<T>(response, effectiveRequestId, args.responseType ?? 'json')
  }

  private buildHeaders(
    args: { headers?: Record<string, string>; jobId: string | null },
    rid: string,
  ): Headers {
    const headers = new Headers(args.headers ?? {})
    headers.set('X-SS-Request-Id', rid)
    if (args.jobId !== null) this.attachAuth(headers, args.jobId)
    return headers
  }

  private attachAuth(headers: Headers, jobId: string): void {
    const token = getAuthToken(jobId)
    if (token !== null && token.trim() !== '') headers.set('Authorization', `Bearer ${token}`)
  }

  private async fetchResponse(
    args: { path: string; method: 'GET' | 'POST'; body?: BodyInit },
    headers: Headers,
    rid: string,
  ): Promise<ApiResult<{ response: Response; effectiveRequestId: string }>> {
    let response: Response
    try {
      response = await fetch(`${this.baseUrl}${args.path}`, { method: args.method, headers, body: args.body })
    } catch (err) {
      return toNetworkError(rid, err)
    }
    const responseRequestId = response.headers.get('X-SS-Request-Id')
    const effectiveRequestId = responseRequestId !== null && responseRequestId.trim() !== '' ? responseRequestId : rid
    return { ok: true, value: { response, effectiveRequestId }, requestId: effectiveRequestId }
  }

  private authErrorIfAny(status: number, jobId: string | null, requestId: string): ApiResult<never> | null {
    if (status !== 401 && status !== 403) return null
    if (jobId !== null) clearAuthToken(jobId)
    return {
      ok: false,
      error: {
        kind: status === 401 ? 'unauthorized' : 'forbidden',
        status,
        message: 'Task Code 已失效/未授权，需要重新兑换',
        requestId,
        details: null,
        action: 'redeem',
      },
    }
  }

  private async httpError(response: Response, requestId: string): Promise<ApiResult<never>> {
    let details: unknown = null
    try {
      details = await safeJson(response)
    } catch (err) {
      details = err
    }
    const message = readErrorMessage(details) ?? `HTTP ${response.status}`
    return { ok: false, error: { kind: 'http', status: response.status, message, requestId, details, action: 'retry' } }
  }

  private async okResult<T>(response: Response, requestId: string, responseType: 'json' | 'blob'): Promise<ApiResult<T>> {
    if (responseType === 'blob') {
      const blob = await response.blob()
      return { ok: true, value: blob as T, requestId }
    }
    try {
      const json = (await safeJson(response)) as T
      return { ok: true, value: json, requestId }
    } catch (err) {
      return toParseError(requestId, err)
    }
  }
}
