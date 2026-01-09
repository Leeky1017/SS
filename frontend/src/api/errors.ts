export type ApiError = {
  status: number | null
  message: string
  requestId: string
  details: unknown
  kind: 'http' | 'network' | 'parse' | 'unauthorized' | 'forbidden'
  action: 'retry' | 'redeem'
}

export type ApiOk<T> = { ok: true; value: T; requestId: string }
export type ApiFail = { ok: false; error: ApiError }
export type ApiResult<T> = ApiOk<T> | ApiFail

export function toNetworkError(requestId: string, details: unknown): ApiFail {
  return {
    ok: false,
    error: {
      kind: 'network',
      status: null,
      message: '网络请求失败，请检查后端服务或稍后重试',
      requestId,
      details,
      action: 'retry',
    },
  }
}

export function toParseError(requestId: string, details: unknown): ApiFail {
  return {
    ok: false,
    error: {
      kind: 'parse',
      status: null,
      message: '响应解析失败（非预期格式）',
      requestId,
      details,
      action: 'retry',
    },
  }
}

