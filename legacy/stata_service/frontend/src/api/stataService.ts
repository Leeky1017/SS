/**
 * Stata Service API Client
 * 对接新的三段式上传流程：redeem -> bundle -> upload -> finalize
 */

const API_BASE: string = '';

// ==================== Types ====================

export interface RedeemResponse {
  job_id: string;
  token: string;
  entitlement: Record<string, unknown>;
  expires_at: string;
  is_idempotent: boolean;
}

export interface BundleFile {
  filename: string;
  size_bytes: number;
  role?: 'main_dataset' | 'merge_table' | 'lookup' | 'appendix' | 'other';
  mime_type?: string;
}

export interface BundleManifest {
  job_id: string;
  files: BundleFile[];
  created_at: string;
}

export interface BundleSheetFileInfo {
  file_id: string;
  filename: string;
  role: string;
  status: string;
  selected_sheet_name: string | null;
  recommended_sheet_name: string | null;
  sheets: DataSourceProfilePublic[];
}

export interface BundleSheetsResponse {
  job_id: string;
  files: BundleSheetFileInfo[];
}

export interface UploadSessionResponse {
  upload_session_id: string;
  job_id: string;
  filename: string;
  upload_strategy: 'direct' | 'multipart';
  presigned_url?: string;
  presigned_urls?: { part_number: number; url: string; expires_at?: string }[];
  part_size?: number;
  expires_at: string;
}

export interface RefreshUploadUrlsResponse {
  session_id: string;
  parts: { part_number: number; url: string; expires_at?: string }[];
}

export interface FinalizeSuccess {
  success: true;
  status: string;
  session_id: string;
  file_id: string;
  sha256?: string;
  size_bytes?: number;
}

export interface FinalizeFailure {
  success: false;
  retryable: boolean;
  error_code: string;
  message: string;
}

export type FinalizeResult = FinalizeSuccess | FinalizeFailure;

export interface Artifact {
  artifact_id: string;
  filename: string;
  size_bytes: number;
  mime_type: string;
  status: 'PENDING' | 'READY' | 'FAILED';
}

// ==================== Document Report Types ====================

export interface DocumentReportFile {
  html?: string;
  word?: string;
  pdf?: string;
}

export interface DocumentReport {
  success: boolean;
  files: DocumentReportFile;
  errors: string[];
}

export interface ArtifactListResponse {
  status: JobBlackboxStatus;
  message: string;
  artifacts?: Artifact[];
  report_formats?: { html: boolean; word: boolean; pdf: boolean };
}

export interface DownloadResponse {
  presigned_url: string;
  expires_at: string;
  expires_in_seconds: number;
}

export interface TaskStatusResponse {
  code_status: string;
  job_id: string;
  entitlement: Record<string, unknown>;
  used_bytes: number;
  remaining_bytes: number;
  resumable_phase: string | null;
  has_bundle: boolean;
  has_draft: boolean;
}

// ==================== Draft Preview Types ====================

export interface OpenUnknown {
  field: string;
  display_name?: string;
  description: string;
  impact: 'low' | 'medium' | 'high' | 'critical';
  blocking?: boolean;
  suggested_default?: unknown;
  candidates?: string[];
}

export interface QuestionOption {
  option_id: string;
  label: string;
  value: unknown;
}

export interface ClarificationQuestion {
  question_id: string;
  question_text: string;
  question_type: 'single_choice' | 'multi_choice';
  options: QuestionOption[];
  priority: number;
}

export interface DefaultValueOption {
  label: string;
  value: unknown;
}

export interface DefaultValueItem {
  field: string;
  display_name: string;
  default_value: unknown;
  default_label: string;
  reason: string;
  editable: boolean;
  options?: DefaultValueOption[] | null;
  source?: 'default' | 'llm' | 'rule' | 'user';
  confidence?: number;
  verified?: boolean;
}

export interface PlaceholderFill {
  value: unknown;
  confidence: number;
  reason?: string;
  verified?: boolean;
  verification_errors?: string[];
}

export interface DataSourceShape {
  n_rows_sample: number;
  n_cols: number;
  numeric_ratio: number;
  id_col_candidates: string[];
  year_col_candidates: string[];
  wide_year_columns: string[];
  is_long_panel_like: boolean;
  is_stacked_wide_year_like: boolean;
}

export interface DataSourceProfilePublic {
  source_id: string;
  file_id: string;
  file_name: string;
  sheet_name: string | null;
  header_row: number;
  cols_preview: string[];
  score: number;
  score_details: Record<string, number>;
  warnings: string[];
  shape: DataSourceShape;
}

export interface DataQualityWarning {
  type: string;
  severity: 'info' | 'warning' | 'error';
  message: string;
  suggestion: string | null;
}

export interface VariableTypeInfo {
  name: string;
  type: 'continuous' | 'categorical' | 'datetime' | 'id' | 'text';
  dtype: string;
  missing_rate: number;
  n_unique: number;
  source?: {
    file_id?: string | null;
    file_name?: string | null;
    sheet_name?: string | null;
  } | null;
}

export interface RequirementCompactMeta {
  original_length?: number;
  compact_length?: number;
  original_text_hash?: string;
  chunks_processed?: number;
  goal_hints?: unknown;
  outcome_hints?: unknown;
  treatment_hints?: unknown;
  method_hints?: unknown;
  sample_hints?: unknown;
  explicit_var_refs?: unknown;
  was_chunked?: boolean;
}

export interface RequirementInfo {
  raw_text: string;
  llm_compact: string;
  compact_meta?: RequirementCompactMeta;
}

export interface EvidenceRef {
  path: string;
}

export interface ExpertSuggestion {
  key: string;
  title: string;
  recommendation: string;
  rationale: string;
  risk: string;
  evidence_refs: EvidenceRef[];
  decision?: 'accepted' | 'rejected';
}

export interface DraftPreviewResponse {
  draft_id: string;
  goal_type: 'descriptive' | 'predictive' | 'causal';
  outcome_var: string | null;
  treatment_var: string | null;
  controls: string[];
  column_candidates?: string[];
  analysis_types?: string[];
  open_unknowns: OpenUnknown[];
  expert_suggestions?: ExpertSuggestion[];
  risk_score: number;
  decision: 'auto_freeze' | 'require_confirm' | 'require_confirm_with_downgrade';
  stage1_questions: ClarificationQuestion[];
  stage2_defaults: DefaultValueItem[];
  stage2_optional: ClarificationQuestion[];
  placeholder_fills?: Record<string, PlaceholderFill>;
  data_quality_warnings?: DataQualityWarning[];
  variable_types?: VariableTypeInfo[];
  status: 'generated' | 'cached' | 'refined' | 'no_data' | 'llm_error' | 'read_error' | 'partial_read_error';
  from_cache?: boolean;
  attempt_index?: number;
  budget_remaining?: number;
  data_sources?: DataSourceProfilePublic[];
  main_data_source_id?: string | null;
  main_data_source_name?: string | null;
  main_data_auto_selected?: boolean;
  requirement?: RequirementInfo;
  default_overrides?: Record<string, unknown>;
  detected_domain?: string;
  recommended_templates?: { id: string; name?: string; reason?: string; priority?: number }[];
  template_steps?: unknown[];
  failed_files?: { filename: string; reason?: string }[];
  successful_files?: string[];
  message?: string;
}

export interface ConfirmDraftResponse {
  job_id: string;
  status: string;
  message: string;
  confirmed_at: string;
  retry_until?: string;
  deferred_window_id?: string;
  confirmed?: boolean;
  analysis_types?: string[];
  analysis_brief?: unknown;
  open_unknowns?: OpenUnknown[];
  expert_suggestions?: ExpertSuggestion[];
  variable_mapping?: {
    outcome_var: string | null;
    treatment_var: string | null;
    controls: string[];
  };
}

// ==================== Token Storage ====================

const TOKEN_KEY = 'stata_service_token';
const JOB_ID_KEY = 'stata_service_job_id';

export function saveAuth(token: string, jobId: string) {
  localStorage.setItem(TOKEN_KEY, token);
  localStorage.setItem(JOB_ID_KEY, jobId);
}

export function getAuth(): { token: string | null; jobId: string | null } {
  return {
    token: localStorage.getItem(TOKEN_KEY),
    jobId: localStorage.getItem(JOB_ID_KEY),
  };
}

export function clearAuth() {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(JOB_ID_KEY);
}

function getAuthHeaders(): HeadersInit {
  const { token } = getAuth();
  if (!token) {
    throw new Error('Not authenticated. Please redeem a task code first.');
  }
  return {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json',
  };
}

function _sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function _getUrlResolutionBase(): string {
  const loc = (globalThis as unknown as { location?: { origin?: string; protocol?: string } }).location;
  const origin = loc?.origin || 'http://localhost';

  try {
    if (API_BASE && /^[a-zA-Z][a-zA-Z0-9+.-]*:\/\//.test(API_BASE)) return API_BASE;
    if (API_BASE && API_BASE.startsWith('//')) return `${loc?.protocol || 'https:'}${API_BASE}`;
    return new URL(API_BASE || '/', origin).toString();
  } catch {
    return origin;
  }
}

function _resolveUrlAgainstApiBase(url: string): string {
  if (!url) return url;
  try {
    return new URL(url, _getUrlResolutionBase()).toString();
  } catch {
    return url;
  }
}

function _extractErrorCodeFromErrorPayload(payload: unknown): string | undefined {
  if (!payload || typeof payload !== 'object') return undefined;
  const obj = payload as Record<string, unknown>;
  const detail = obj.detail;

  if (detail && typeof detail === 'object') {
    const d = detail as Record<string, unknown>;
    if (typeof d.error_code === 'string' && d.error_code) return d.error_code;
    if (typeof d.error === 'string' && d.error) return d.error;
  }
  if (typeof obj.error_code === 'string' && obj.error_code) return obj.error_code;
  if (typeof obj.error === 'string' && obj.error) return obj.error;
  return undefined;
}

// ==================== 任务包 2：技术细节过滤 ====================
// 检测并过滤可能泄露技术细节的消息

const TECHNICAL_PATTERNS = [
  /Traceback/i,
  /File ".*"/i,
  /line \d+/i,
  /Error:/i,
  /Exception:/i,
  /at 0x[0-9a-fA-F]+/i,
  /\/home\//i,
  /\/usr\//i,
  /\\Users\\/i,
  /\.py:/i,
  /httpx\./i,
  /openai\./i,
  /anthropic\./i,
  /requests\./i,
  /aiohttp\./i,
  /asyncio\./i,
  /timeout/i,
  /connection refused/i,
  /connection reset/i,
  /ssl/i,
  /certificate/i,
  /api[_-]?key/i,
  /token/i,
  /secret/i,
  /password/i,
  /credential/i,
];

/**
 * 检测消息是否包含技术细节
 */
function containsTechnicalDetails(message: string): boolean {
  if (!message) return false;
  return TECHNICAL_PATTERNS.some((pattern) => pattern.test(message));
}

/**
 * 获取安全的用户消息（过滤技术细节）
 */
export function getSafeUserMessage(message: string, fallback = '系统处理异常，请稍后重试'): string {
  if (!message) return fallback;
  if (containsTechnicalDetails(message)) return fallback;
  return message;
}

/**
 * 过滤 open_unknowns 中的技术细节
 */
export function sanitizeOpenUnknowns(unknowns: OpenUnknown[]): OpenUnknown[] {
  if (!Array.isArray(unknowns)) return [];
  return unknowns.map((u) => ({
    ...u,
    description: getSafeUserMessage(u.description, '需要补充信息'),
  }));
}

async function fetchWithLockTimeoutRetry(
  url: string,
  init: RequestInit,
  options?: { retries?: number; baseDelayMs?: number }
): Promise<Response> {
  const retries = options?.retries ?? 3;
  let delayMs = options?.baseDelayMs ?? 200;
  const maxDelayMs = 1500;

  for (let attempt = 0; attempt <= retries; attempt++) {
    const response = await fetch(url, init);
    if (response.status !== 503) return response;

    const payload = await response.clone().json().catch(() => null);
    const errorCode = _extractErrorCodeFromErrorPayload(payload);
    if (errorCode !== 'LOCK_TIMEOUT') return response;
    if (attempt === retries) return response;

    const jitter = Math.floor(Math.random() * 100);
    await _sleep(delayMs + jitter);
    delayMs = Math.min(maxDelayMs, delayMs * 2);
  }

  return fetch(url, init);
}

// ==================== API Functions ====================

/**
 * Helper to extract error message from API response
 */
const ERROR_CODE_MESSAGES: Record<string, string> = {
  RATE_LIMITED: '请求过于频繁',
  DOWNLOAD_LIMIT_EXCEEDED: '下载次数已达上限',
  CHECKSUM_MISMATCH: '文件校验失败',
  PREVIEW_TIMEOUT: '分析等待时间较长',
  URL_EXPIRED: '上传链接已过期，请重试',
  LOCK_TIMEOUT: '系统繁忙，请稍后重试',
  TOKEN_REVOKED: '任务码已失效',
  INVALID_CODE_FORMAT: '任务码格式不正确',
};

function getLocalizedError(code: string, fallback: string): string {
  return ERROR_CODE_MESSAGES[code] || fallback;
}

function extractErrorMessage(error: unknown, fallback: string): string {
  if (!error) return fallback;
  if (typeof error === 'string') return error;
  if (typeof error !== 'object') return fallback;

  const e = error as Record<string, unknown>;
  const detail = e.detail as Record<string, unknown> | string | undefined;
  const errorCode =
    (detail && typeof detail === 'object' && typeof detail.error_code === 'string' && detail.error_code) ||
    (detail && typeof detail === 'object' && typeof detail.error === 'string' && detail.error) ||
    (typeof e.error_code === 'string' && e.error_code) ||
    (typeof e.error === 'string' && e.error);

  const message =
    (typeof e.message === 'string' && e.message) ||
    (typeof detail === 'string' && detail) ||
    (detail && typeof detail === 'object' && typeof detail.message === 'string' && detail.message) ||
    (typeof e.error_message === 'string' && e.error_message) ||
    (detail && typeof detail === 'object' && typeof detail.error_message === 'string' && detail.error_message);

  if (message) return message;
  if (errorCode) return getLocalizedError(errorCode, fallback);
  return fallback;
}

async function handleRateLimitResponse(response: Response): Promise<never> {
  const retryAfter = response.headers.get('Retry-After');
  const parsed = retryAfter ? parseInt(retryAfter, 10) : NaN;
  const seconds = Number.isFinite(parsed) && parsed > 0 ? parsed : 60;

  throw {
    type: 'RATE_LIMITED',
    retryAfter: seconds,
    message: `请求过于频繁，请在 ${seconds} 秒后重试`,
  };
}

/**
 * Step 1: Redeem task code to get job_id and token
 */
export async function redeemTaskCode(code: string): Promise<RedeemResponse> {
  const response = await fetchWithLockTimeoutRetry(`${API_BASE}/task-codes/redeem`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ code }),
  });

  if (response.status === 429) {
    await handleRateLimitResponse(response);
  }

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'Unknown error' }));
    throw new Error(extractErrorMessage(error, `Redeem failed: ${response.status}`));
  }

  const data: RedeemResponse = await response.json();
  saveAuth(data.token, data.job_id);
  return data;
}

/**
 * Get task code status (requires token)
 */
export async function getTaskCodeStatus(): Promise<TaskStatusResponse> {
  const response = await fetchWithLockTimeoutRetry(`${API_BASE}/task-codes/status`, {
    method: 'GET',
    headers: getAuthHeaders(),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'Unknown error' }));
    throw new Error(extractErrorMessage(error, `Status check failed: ${response.status}`));
  }

  return response.json();
}

/**
 * Step 2: Create bundle - declare files to be uploaded
 */
export async function createBundle(jobId: string, files: BundleFile[], description?: string): Promise<BundleManifest> {
  const response = await fetchWithLockTimeoutRetry(`${API_BASE}/jobs/${jobId}/bundle`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({ files, description: description || '' }),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'Unknown error' }));
    throw new Error(extractErrorMessage(error, `Bundle creation failed: ${response.status}`));
  }

  return response.json();
}

/**
 * Get existing bundle
 */
export async function getBundle(jobId: string): Promise<BundleManifest> {
  const response = await fetchWithLockTimeoutRetry(`${API_BASE}/jobs/${jobId}/bundle`, {
    method: 'GET',
    headers: getAuthHeaders(),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'Unknown error' }));
    throw new Error(extractErrorMessage(error, `Get bundle failed: ${response.status}`));
  }

  return response.json();
}

/**
 * Get bundle sheet options (Excel multi-sheet only)
 */
export async function getBundleSheets(jobId: string): Promise<BundleSheetsResponse> {
  const response = await fetchWithLockTimeoutRetry(`${API_BASE}/jobs/${jobId}/bundle/sheets`, {
    method: 'GET',
    headers: getAuthHeaders(),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'Unknown error' }));
    throw new Error(extractErrorMessage(error, `Get bundle sheets failed: ${response.status}`));
  }

  return response.json();
}

/**
 * Patch bundle sheet selections (by file_id)
 */
export async function patchBundleSheets(
  jobId: string,
  selections: Record<string, string>
): Promise<{ job_id: string; updated: { file_id: string; filename: string; selected_sheet_name: string }[] }> {
  const response = await fetchWithLockTimeoutRetry(`${API_BASE}/jobs/${jobId}/bundle/sheets`, {
    method: 'PATCH',
    headers: getAuthHeaders(),
    body: JSON.stringify({ selections }),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'Unknown error' }));
    throw new Error(extractErrorMessage(error, `Patch bundle sheets failed: ${response.status}`));
  }

  return response.json();
}

/**
 * Step 3: Create upload session - get presigned URLs
 */
export async function createUploadSession(
  jobId: string,
  filename: string,
  sizeBytes: number,
  mimeType?: string
): Promise<UploadSessionResponse> {
  const response = await fetchWithLockTimeoutRetry(`${API_BASE}/jobs/${jobId}/upload-sessions`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({
      filename,
      size_bytes: sizeBytes,
      mime_type: mimeType || 'application/octet-stream',
    }),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'Unknown error' }));
    throw new Error(extractErrorMessage(error, `Upload session creation failed: ${response.status}`));
  }

  const data = (await response.json()) as UploadSessionResponse;
  if (data.presigned_url) {
    data.presigned_url = _resolveUrlAgainstApiBase(data.presigned_url);
  }
  if (Array.isArray(data.presigned_urls)) {
    data.presigned_urls = data.presigned_urls.map((p) => ({ ...p, url: _resolveUrlAgainstApiBase(p.url) }));
  }
  return data;
}

/**
 * Refresh presigned URLs for an existing upload session
 */
export async function refreshUploadUrls(
  uploadSessionId: string,
  partNumbers?: number[]
): Promise<RefreshUploadUrlsResponse> {
  const response = await fetchWithLockTimeoutRetry(`${API_BASE}/upload-sessions/${uploadSessionId}/refresh-urls`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify(partNumbers && partNumbers.length > 0 ? { part_numbers: partNumbers } : {}),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'Unknown error' }));
    throw new Error(extractErrorMessage(error, `Refresh upload URLs failed: ${response.status}`));
  }

  const data = (await response.json()) as RefreshUploadUrlsResponse;
  if (Array.isArray(data.parts)) {
    data.parts = data.parts.map((p) => ({ ...p, url: _resolveUrlAgainstApiBase(p.url) }));
  }
  return data;
}

class PresignedUploadError extends Error {
  status: number;
  errorCode?: string;
  rawResponse?: string;

  constructor(message: string, status: number, errorCode?: string, rawResponse?: string) {
    super(message);
    this.name = 'PresignedUploadError';
    this.status = status;
    this.errorCode = errorCode;
    this.rawResponse = rawResponse;
  }
}

function _safeParseJson(text: string): unknown {
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

function _extractErrorCodeFromXhrResponse(responseText: string): string | undefined {
  if (!responseText) return undefined;
  const parsed = _safeParseJson(responseText);
  if (!parsed || typeof parsed !== 'object') return undefined;
  const obj = parsed as Record<string, unknown>;
  const detail = obj.detail;
  if (detail && typeof detail === 'object') {
    const d = detail as Record<string, unknown>;
    if (typeof d.error_code === 'string' && d.error_code) return d.error_code;
    if (typeof d.error === 'string' && d.error) return d.error;
  }
  if (typeof obj.error_code === 'string' && obj.error_code) return obj.error_code;
  if (typeof obj.error === 'string' && obj.error) return obj.error;
  return undefined;
}

function _getExpiresEpochSecondsFromPresignedUrl(presignedUrl: string): number | null {
  if (!presignedUrl) return null;
  try {
    const u = new URL(_resolveUrlAgainstApiBase(presignedUrl));
    const expiresRaw = u.searchParams.get('expires');
    if (expiresRaw) {
      const expires = parseInt(expiresRaw, 10);
      return Number.isFinite(expires) && expires > 0 ? expires : null;
    }
  } catch {
    return null;
  }
  return null;
}

async function _ensureFreshPresignedUrl(
  uploadSessionId: string,
  partNumber: number,
  presignedUrl: string,
  safetyWindowSeconds: number = 60
): Promise<string> {
  const expires = _getExpiresEpochSecondsFromPresignedUrl(presignedUrl);
  if (!expires) return _resolveUrlAgainstApiBase(presignedUrl);

  const now = Math.floor(Date.now() / 1000);
  if (now + safetyWindowSeconds < expires) return _resolveUrlAgainstApiBase(presignedUrl);

  const refreshed = await refreshUploadUrls(uploadSessionId, [partNumber]);
  const part = refreshed.parts.find((p) => p.part_number === partNumber);
  if (!part?.url) {
    throw new Error('服务器未返回续期后的上传地址');
  }
  return _resolveUrlAgainstApiBase(part.url);
}

/**
 * Pure JavaScript SHA256 implementation for non-HTTPS environments
 */
function sha256Fallback(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  const K = new Uint32Array([
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
  ]);
  let h0 = 0x6a09e667, h1 = 0xbb67ae85, h2 = 0x3c6ef372, h3 = 0xa54ff53a;
  let h4 = 0x510e527f, h5 = 0x9b05688c, h6 = 0x1f83d9ab, h7 = 0x5be0cd19;
  const newLen = bytes.length + 1 + 8 + (64 - ((bytes.length + 1 + 8) % 64)) % 64;
  const padded = new Uint8Array(newLen);
  padded.set(bytes);
  padded[bytes.length] = 0x80;
  const view = new DataView(padded.buffer);
  // 64-bit length (big-endian): high 32 bits then low 32 bits.
  // Note: bytes.length is capped by JS number precision; this covers practical file sizes.
  const bitLenLo = (bytes.length << 3) >>> 0;
  const bitLenHi = (bytes.length >>> 29) >>> 0;
  view.setUint32(newLen - 8, bitLenHi, false);
  view.setUint32(newLen - 4, bitLenLo, false);
  const W = new Uint32Array(64);
  for (let i = 0; i < newLen; i += 64) {
    for (let j = 0; j < 16; j++) { W[j] = view.getUint32(i + j * 4, false); }
    for (let j = 16; j < 64; j++) {
      const s0 = ((W[j - 15] >>> 7) | (W[j - 15] << 25)) ^ ((W[j - 15] >>> 18) | (W[j - 15] << 14)) ^ (W[j - 15] >>> 3);
      const s1 = ((W[j - 2] >>> 17) | (W[j - 2] << 15)) ^ ((W[j - 2] >>> 19) | (W[j - 2] << 13)) ^ (W[j - 2] >>> 10);
      W[j] = (W[j - 16] + s0 + W[j - 7] + s1) >>> 0;
    }
    let a = h0, b = h1, c = h2, d = h3, e = h4, f = h5, g = h6, h = h7;
    for (let j = 0; j < 64; j++) {
      const S1 = ((e >>> 6) | (e << 26)) ^ ((e >>> 11) | (e << 21)) ^ ((e >>> 25) | (e << 7));
      const ch = (e & f) ^ (~e & g);
      const temp1 = (h + S1 + ch + K[j] + W[j]) >>> 0;
      const S0 = ((a >>> 2) | (a << 30)) ^ ((a >>> 13) | (a << 19)) ^ ((a >>> 22) | (a << 10));
      const maj = (a & b) ^ (a & c) ^ (b & c);
      const temp2 = (S0 + maj) >>> 0;
      h = g; g = f; f = e; e = (d + temp1) >>> 0;
      d = c; c = b; b = a; a = (temp1 + temp2) >>> 0;
    }
    h0 = (h0 + a) >>> 0; h1 = (h1 + b) >>> 0; h2 = (h2 + c) >>> 0; h3 = (h3 + d) >>> 0;
    h4 = (h4 + e) >>> 0; h5 = (h5 + f) >>> 0; h6 = (h6 + g) >>> 0; h7 = (h7 + h) >>> 0;
  }
  const toHex = (n: number) => n.toString(16).padStart(8, '0');
  return toHex(h0) + toHex(h1) + toHex(h2) + toHex(h3) + toHex(h4) + toHex(h5) + toHex(h6) + toHex(h7);
}

function generateUuidV4(): string {
  const cryptoObj = globalThis.crypto;
  if (cryptoObj?.getRandomValues) {
    const bytes = new Uint8Array(16);
    cryptoObj.getRandomValues(bytes);
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    const hex = Array.from(bytes, (b) => b.toString(16).padStart(2, '0'));
    return `${hex.slice(0, 4).join('')}-${hex.slice(4, 6).join('')}-${hex.slice(6, 8).join('')}-${hex.slice(8, 10).join('')}-${hex.slice(10).join('')}`;
  }
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

/**
 * Calculate SHA256 hash of file/blob (with HTTP fallback)
 */
async function calculateSHA256(data: Blob): Promise<string> {
  const arrayBuffer = await data.arrayBuffer();
  const subtle = globalThis.crypto?.subtle;
  if (subtle && typeof subtle.digest === 'function') {
    try {
      const hashBuffer = await subtle.digest('SHA-256', arrayBuffer);
      const hashArray = Array.from(new Uint8Array(hashBuffer));
      return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
    } catch { /* fall through */ }
  }
  return sha256Fallback(arrayBuffer);
}

/**
 * Step 4: Upload file directly to presigned URL
 * Returns: { etag, sha256 }
 */
export async function uploadToPresignedUrl(
  presignedUrl: string,
  file: File,
  onProgress?: (progress: number) => void
): Promise<{ etag: string; sha256: string }> {
  // Calculate SHA256 first
  const sha256 = await calculateSHA256(file);

  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();

    xhr.upload.addEventListener('progress', (e) => {
      if (e.lengthComputable && onProgress) {
        onProgress((e.loaded / e.total) * 100);
      }
    });

    xhr.addEventListener('load', () => {
      if (xhr.status >= 200 && xhr.status < 300) {
        const etag = xhr.getResponseHeader('ETag') || '';
        resolve({ etag: etag.replace(/"/g, ''), sha256 });
      } else {
        const responseText = xhr.responseText || '';
        const errorCode = _extractErrorCodeFromXhrResponse(responseText);
        reject(new PresignedUploadError(`Upload failed: ${xhr.status}`, xhr.status, errorCode, responseText));
      }
    });

    xhr.addEventListener('error', () => {
      reject(new PresignedUploadError('Upload failed: Network error', 0));
    });

    xhr.open('PUT', _resolveUrlAgainstApiBase(presignedUrl));
    xhr.setRequestHeader('Content-Type', file.type || 'application/octet-stream');
    xhr.send(file);
  });
}

async function uploadToPresignedUrlWithAutoRefresh(
  uploadSessionId: string,
  partNumber: number,
  presignedUrl: string,
  file: File,
  onProgress?: (progress: number) => void
): Promise<{ etag: string; sha256: string }> {
  let currentUrl = await _ensureFreshPresignedUrl(uploadSessionId, partNumber, presignedUrl);
  try {
    return await uploadToPresignedUrl(currentUrl, file, onProgress);
  } catch (err) {
    const e = err as unknown;
    if (e instanceof PresignedUploadError) {
      const shouldRefresh =
        e.errorCode === 'URL_EXPIRED' ||
        (e.status === 403 && !e.errorCode); // CORS/非 JSON 场景下的兜底
      if (shouldRefresh) {
        const refreshed = await refreshUploadUrls(uploadSessionId, [partNumber]);
        const part = refreshed.parts.find((p) => p.part_number === partNumber);
        if (!part?.url) {
          throw new Error('上传链接已过期，且续期失败（未返回新链接）');
        }
        currentUrl = _resolveUrlAgainstApiBase(part.url);
        return await uploadToPresignedUrl(currentUrl, file, onProgress);
      }
    }
    throw err;
  }
}

/**
 * Step 5: Finalize upload session
 */
export async function finalizeUpload(
  uploadSessionId: string,
  parts: { part_number: number; etag: string; sha256?: string }[]
): Promise<FinalizeResult> {
  const response = await fetchWithLockTimeoutRetry(`${API_BASE}/upload-sessions/${uploadSessionId}/finalize`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({ parts }),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'Unknown error' }));
    const detail = (error && typeof error === 'object' && 'detail' in error)
      ? (error as { detail?: Record<string, unknown> }).detail
      : undefined;
    const errorCode = (detail && typeof detail === 'object' && 'error_code' in detail)
      ? String((detail as { error_code?: unknown }).error_code || '')
      : '';
    if (errorCode === 'CHECKSUM_MISMATCH') {
      return {
        success: false,
        retryable: true,
        error_code: 'CHECKSUM_MISMATCH',
        message: '文件校验失败，请重新上传',
      };
    }
    throw new Error(extractErrorMessage(error, `Finalize failed: ${response.status}`));
  }

  const data = await response.json();
  return {
    success: true,
    status: data.status,
    session_id: data.session_id,
    file_id: data.file_id,
    sha256: data.sha256,
    size_bytes: data.size_bytes,
  };
}

/**
 * Step 6: List artifacts
 */
export async function listArtifacts(jobId: string): Promise<ArtifactListResponse> {
  const response = await fetchWithLockTimeoutRetry(`${API_BASE}/jobs/${jobId}/artifacts`, {
    method: 'GET',
    headers: getAuthHeaders(),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'Unknown error' }));
    throw new Error(extractErrorMessage(error, `List artifacts failed: ${response.status}`));
  }

  return response.json();
}

// ==================== Job Status ====================

export type JobBlackboxStatus = 'processing' | 'done' | 'failed' | string;

export interface JobStatusResponse {
  status: JobBlackboxStatus;
  message: string;
  retry_until?: string;
}

export async function getJobStatus(jobId: string): Promise<JobStatusResponse> {
  const response = await fetchWithLockTimeoutRetry(`${API_BASE}/jobs/${jobId}/status`, {
    method: 'GET',
    headers: getAuthHeaders(),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'Unknown error' }));
    throw new Error(extractErrorMessage(error, `Get job status failed: ${response.status}`));
  }

  return response.json();
}

/**
 * Step 7: Get download URL for single artifact
 */
export async function getArtifactDownloadUrl(
  jobId: string,
  artifactId: string
): Promise<DownloadResponse> {
  const response = await fetchWithLockTimeoutRetry(`${API_BASE}/jobs/${jobId}/artifacts/${artifactId}/download`, {
    method: 'GET',
    headers: getAuthHeaders(),
  });

  // 显式处理 202 Pending
  if (response.status === 202) {
    const data = await response.json().catch(() => ({}));
    throw new Error(String((data as { message?: unknown }).message || '任务处理中，暂不可下载'));
  }

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'Unknown error' }));
    throw new Error(extractErrorMessage(error, `Get download URL failed: ${response.status}`));
  }

  const data = (await response.json()) as DownloadResponse;
  if (data.presigned_url) {
    data.presigned_url = _resolveUrlAgainstApiBase(data.presigned_url);
  }
  return data;
}

/**
 * Step 8: Request ZIP of all artifacts
 */
export async function requestArtifactsZip(jobId: string): Promise<{
  status: JobBlackboxStatus;
  message: string;
  presigned_url?: string;
  expires_at?: string;
}> {
  const response = await fetchWithLockTimeoutRetry(`${API_BASE}/jobs/${jobId}/artifacts/zip`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({}),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'Unknown error' }));
    throw new Error(extractErrorMessage(error, `Request ZIP failed: ${response.status}`));
  }

  const data = (await response.json()) as {
    status: JobBlackboxStatus;
    message: string;
    presigned_url?: string;
    expires_at?: string;
  };
  if (data.presigned_url) {
    data.presigned_url = _resolveUrlAgainstApiBase(data.presigned_url);
  }
  return data;
}

// ==================== Document Report Download ====================

/**
 * 下载文档报告
 * @param jobId 任务 ID
 * @param format 报告格式 ('html' | 'word' | 'pdf')
 */
export async function downloadReport(jobId: string, format: 'html' | 'word' | 'pdf'): Promise<void> {
  const response = await fetchWithLockTimeoutRetry(`${API_BASE}/jobs/${jobId}/reports/${format}`, {
    method: 'GET',
    headers: getAuthHeaders(),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'Unknown error' }));
    throw new Error(extractErrorMessage(error, `Failed to download report: ${response.status}`));
  }

  const blob = await response.blob();
  const url = window.URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `report.${format === 'word' ? 'docx' : format}`;
  document.body.appendChild(a);
  a.click();
  window.URL.revokeObjectURL(url);
  document.body.removeChild(a);
}

// ==================== High-level Upload Flow ====================

export interface UploadProgress {
  filename: string;
  progress: number;
  status: 'pending' | 'uploading' | 'finalizing' | 'done' | 'error';
  error?: string;
}

/**
 * Complete upload flow for a single file
 */
export async function uploadFile(
  jobId: string,
  file: File,
  onProgress?: (progress: UploadProgress) => void
): Promise<void> {
  const filename = file.name;

  try {
    onProgress?.({ filename, progress: 0, status: 'pending' });

    const MAX_RETRIES = 3;
    for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
      try {
        if (attempt > 0) {
          onProgress?.({ filename, progress: 0, status: 'uploading' });
        }

        // Create upload session
        const session = await createUploadSession(jobId, filename, file.size, file.type);

        onProgress?.({ filename, progress: 5, status: 'uploading' });

        let finalizeResult: FinalizeResult;

        // Upload to presigned URL (auto refresh on expiry)
        if (session.upload_strategy === 'direct' && session.presigned_url) {
          const { etag, sha256 } = await uploadToPresignedUrlWithAutoRefresh(
            session.upload_session_id,
            1,
            session.presigned_url,
            file,
            (p) => {
              onProgress?.({ filename, progress: 5 + p * 0.9, status: 'uploading' });
            }
          );

          onProgress?.({ filename, progress: 95, status: 'finalizing' });

          // Finalize with SHA256
          finalizeResult = await finalizeUpload(session.upload_session_id, [{ part_number: 1, etag, sha256 }]);
        } else if (session.upload_strategy === 'multipart') {
          if (!session.presigned_urls || session.presigned_urls.length === 0) {
            throw new Error('服务器未返回上传地址，请检查文件');
          }
          // Multipart upload implementation
          const partSize = session.part_size || 5 * 1024 * 1024; // Default 5MB
          const parts: { part_number: number; etag: string; sha256: string }[] = [];
          const totalParts = session.presigned_urls.length;

          for (const partInfo of session.presigned_urls) {
            const start = (partInfo.part_number - 1) * partSize;
            const end = Math.min(start + partSize, file.size);
            const chunk = file.slice(start, end);
            const chunkFile = new File([chunk], file.name, { type: file.type });

            // Upload this part (auto refresh on expiry)
            const { etag, sha256 } = await uploadToPresignedUrlWithAutoRefresh(
              session.upload_session_id,
              partInfo.part_number,
              partInfo.url,
              chunkFile,
              (p) => {
                // Calculate total progress across all parts
                const completedParts = partInfo.part_number - 1;
                const currentPartProgress = p / 100;
                const totalProgress = ((completedParts + currentPartProgress) / totalParts) * 90;
                onProgress?.({ filename, progress: 5 + totalProgress, status: 'uploading' });
              }
            );

            parts.push({ part_number: partInfo.part_number, etag, sha256 });
          }

          onProgress?.({ filename, progress: 95, status: 'finalizing' });

          // Finalize multipart upload with SHA256
          finalizeResult = await finalizeUpload(session.upload_session_id, parts);
        } else {
          throw new Error('Invalid upload session: missing presigned URL(s)');
        }

        if (finalizeResult.success) {
          onProgress?.({ filename, progress: 100, status: 'done' });
          return;
        }

        const failure = finalizeResult as FinalizeFailure;
        if (!failure.retryable || attempt === MAX_RETRIES - 1) {
          throw new Error(failure.message);
        }
      } catch (err) {
        if (attempt === MAX_RETRIES - 1) {
          throw err;
        }
        // Retry by creating a new upload session (e.g., network errors)
        continue;
      }
    }
  } catch (error) {
    onProgress?.({
      filename,
      progress: 0,
      status: 'error',
      error: error instanceof Error ? error.message : 'Unknown error',
    });
    throw error;
  }
}

/**
 * Complete submission flow: redeem -> bundle -> upload all files -> finalize
 */
export async function submitTask(
  taskCode: string,
  files: File[],
  mainDataIndex: number,  // User-selected main data file index
  description: string,
  onProgress?: (fileProgress: UploadProgress[]) => void
): Promise<{ jobId: string; token: string }> {
  // Step 1: Redeem
  const redeemResult = await redeemTaskCode(taskCode);
  const { job_id: jobId, token } = redeemResult;

  // Step 2: Create bundle (with description)
  // Use user-selected mainDataIndex for role assignment
  const dataExtensions = ['.dta', '.xlsx', '.xls', '.csv'];

  const bundleFiles: BundleFile[] = files.map((f, index) => {
    const ext = f.name.toLowerCase().slice(f.name.lastIndexOf('.'));
    const isDataFile = dataExtensions.includes(ext);
    let role: 'main_dataset' | 'merge_table' | 'appendix' = 'appendix';

    if (index === mainDataIndex) {
      role = 'main_dataset';
    } else if (isDataFile) {
      role = 'merge_table';
    }

    return {
      filename: f.name,
      size_bytes: f.size,
      mime_type: f.type || 'application/octet-stream',
      role,
    };
  });
  await createBundle(jobId, bundleFiles, description);

  // Step 3-5: Upload each file
  const progresses: UploadProgress[] = files.map((f) => ({
    filename: f.name,
    progress: 0,
    status: 'pending' as const,
  }));

  for (let i = 0; i < files.length; i++) {
    await uploadFile(jobId, files[i], (p) => {
      progresses[i] = p;
      onProgress?.([...progresses]);
    });
  }

  return { jobId, token };
}

// ==================== Draft Preview & Confirm API ====================

/**
 * Get draft preview with clarification questions
 */
export interface GetDraftPreviewOptions {
  force?: boolean;
  mainDataSourceId?: string;
}

export class PreviewTimeoutError extends Error {
  type = 'TIMEOUT' as const;
  retryAfter: number;
  status?: string;
  serverMessage?: string;
  retryUntil?: string;

  constructor(opts: { retryAfter: number; status?: string; serverMessage?: string; retryUntil?: string }) {
    super('预处理中，系统将自动重试，请稍等…');
    this.name = 'PreviewTimeoutError';
    this.retryAfter = opts.retryAfter;
    this.status = opts.status;
    this.serverMessage = opts.serverMessage;
    this.retryUntil = opts.retryUntil;
  }
}

export async function getDraftPreview(
  jobId: string,
  options?: GetDraftPreviewOptions
): Promise<DraftPreviewResponse> {
  const params = new URLSearchParams();
  if (options?.mainDataSourceId) params.set('main_data_source_id', options.mainDataSourceId);
  const query = params.toString();
  const regenerate = Boolean(options?.force);
  const url = regenerate
    ? `${API_BASE}/jobs/${jobId}/draft/preview/regenerate${query ? `?${query}` : ''}`
    : `${API_BASE}/jobs/${jobId}/draft/preview${query ? `?${query}` : ''}`;

  const controller = new AbortController();
  // Backend default timeout is 120s; keep a bit of headroom for network/JSON.
  // Frontend timeout should be slightly larger than backend SS_PREVIEW_TIMEOUT_SECONDS (default 300s)
  const timeoutId = setTimeout(() => controller.abort(), 310000);

  try {
    const idempotencyKey = regenerate ? (globalThis.crypto?.randomUUID?.() ?? generateUuidV4()) : undefined;
    const response = await fetchWithLockTimeoutRetry(url, {
      method: regenerate ? 'POST' : 'GET',
      headers: regenerate
        ? {
            ...getAuthHeaders(),
            'X-Idempotency-Key': String(idempotencyKey),
          }
        : getAuthHeaders(),
      signal: controller.signal,
    });

    // 显式处理 202 timeout/pending
    if (response.status === 202) {
      const data = await response.json();
      const retryAfter = Number(data?.retry_after_seconds) || 5;
      const status = typeof data?.status === 'string' ? data.status : undefined;
      const serverMessage = typeof data?.message === 'string' ? data.message : undefined;
      const retryUntil = typeof data?.retry_until === 'string' ? data.retry_until : undefined;
      throw new PreviewTimeoutError({ retryAfter, status, serverMessage, retryUntil });
    }

    if (!response.ok) {
      const error = await response.json().catch(() => ({ detail: 'Unknown error' }));
      throw new Error(extractErrorMessage(error, `Draft preview failed: ${response.status}`));
    }

    return response.json();
  } catch (error) {
    if (error instanceof Error && error.name === 'AbortError') {
      throw new Error('请求等待时间较长，请稍后再试');
    }
    throw error;
  } finally {
    clearTimeout(timeoutId);
  }
}

/**
 * Confirm draft with user answers
 */
export async function confirmDraft(
  jobId: string,
  answers: Record<string, string[]>,
  defaultOverrides?: Record<string, unknown>,
  variableCorrections?: Record<string, string>,
  expertSuggestionsFeedback?: Record<string, boolean>,
  confirmed: boolean = true
): Promise<ConfirmDraftResponse> {
  const idempotencyKey = globalThis.crypto?.randomUUID?.() ?? generateUuidV4();
  const response = await fetchWithLockTimeoutRetry(`${API_BASE}/jobs/${jobId}/confirm`, {
    method: 'POST',
    headers: {
      ...getAuthHeaders(),
      'X-Idempotency-Key': idempotencyKey,
    },
    body: JSON.stringify({
      confirmed,
      variable_corrections: variableCorrections || {},
      answers,
      default_overrides: defaultOverrides || {},
      expert_suggestions_feedback: expertSuggestionsFeedback || {},
    }),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'Unknown error' }));
    throw new Error(extractErrorMessage(error, `Confirm failed: ${response.status}`));
  }

  return response.json();
}

/**
 * Refine draft with user clarification
 */
export async function refineDraft(
  jobId: string,
  clarification: string
): Promise<DraftPreviewResponse> {
  const response = await fetchWithLockTimeoutRetry(`${API_BASE}/jobs/${jobId}/draft/refine`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({ clarification }),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'Unknown error' }));
    throw new Error(extractErrorMessage(error, `Draft refinement failed: ${response.status}`));
  }

  return response.json();
}

// ==================== Append Files API (UX-002) ====================

export interface AppendFilesResponse {
  job_id: string;
  appended_files: string[];
  message: string;
}

/**
 * Append additional files to an existing job (confirmation page).
 */
export async function appendFiles(
  jobId: string,
  files: File[],
  onProgress?: (fileProgress: UploadProgress[]) => void
): Promise<AppendFilesResponse> {
  if (files.length === 0) {
    return { job_id: jobId, appended_files: [], message: 'No files to append' };
  }

  const progresses: UploadProgress[] = files.map((f) => ({
    filename: f.name,
    progress: 0,
    status: 'pending' as const,
  }));

  for (let i = 0; i < files.length; i++) {
    await uploadFile(jobId, files[i], (p) => {
      progresses[i] = p;
      onProgress?.([...progresses]);
    });
  }

  return {
    job_id: jobId,
    appended_files: files.map((f) => f.name),
    message: 'Additional files uploaded',
  };
}

// ==================== Data Source Selection API (P4) ====================

export interface SelectSourceResponse {
  status: string;
  main_data_source_id: string;
  main_data_auto_selected: boolean;
  data_sources: DataSourceProfilePublic[];
}

/**
 * Select data source (P4: Sheet selection transparency)
 * 
 * Allows users to manually select a data source when Excel file contains
 * multiple sheets.
 */
export async function selectDataSource(
  jobId: string,
  sourceId: string
): Promise<SelectSourceResponse> {
  const response = await fetchWithLockTimeoutRetry(`${API_BASE}/jobs/${jobId}/select-source`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({ source_id: sourceId }),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'Unknown error' }));
    throw new Error(extractErrorMessage(error, `Select source failed: ${response.status}`));
  }

  return response.json();
}

// ==================== Draft Patch API (Inline Clarification) ====================

export interface DraftPatchResponse {
  status: string;
  patched_fields: string[];
  remaining_unknowns_count: number;
  open_unknowns: OpenUnknown[];
  draft_preview: {
    goal_type: string;
    outcome_var: string | null;
    treatment_var: string | null;
    controls: string[] | null;
  };
}

/**
 * Patch draft with field updates (Inline Clarification - 改正带模式)
 * 
 * Applies user clarifications directly to the existing draft without
 * re-calling LLM. Automatically removes resolved open_unknowns.
 * 
 * @param jobId - Job ID
 * @param fieldUpdates - Map of field paths to new values
 * @returns Updated draft preview with remaining unknowns
 */
export async function patchDraft(
  jobId: string,
  fieldUpdates: Record<string, unknown>
): Promise<DraftPatchResponse> {
  const response = await fetchWithLockTimeoutRetry(`${API_BASE}/jobs/${jobId}/draft/patch`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({ field_updates: fieldUpdates }),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'Unknown error' }));
    throw new Error(extractErrorMessage(error, `Patch draft failed: ${response.status}`));
  }

  return response.json();
}
