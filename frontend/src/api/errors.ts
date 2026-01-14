import { toUserErrorMessage } from '../utils/errorCodes'

export type ApiError = {
  status: number | null
  message: string
  requestId: string
  details: unknown
  internalCode: string | null
  kind: 'http' | 'network' | 'parse' | 'unauthorized' | 'forbidden'
  action: 'retry' | 'redeem'
}

export type ApiOk<T> = { ok: true; value: T; requestId: string }
export type ApiFail = { ok: false; error: ApiError }
export type ApiResult<T> = ApiOk<T> | ApiFail

export function toNetworkError(requestId: string, details: unknown): ApiFail {
  const internalCode = 'CLIENT_NETWORK_ERROR'
  return {
    ok: false,
    error: {
      kind: 'network',
      status: null,
      message: toUserErrorMessage({ internalCode, kind: 'network', status: null }),
      requestId,
      details,
      internalCode,
      action: 'retry',
    },
  }
}

export function toParseError(requestId: string, details: unknown): ApiFail {
  const internalCode = 'CLIENT_PARSE_ERROR'
  return {
    ok: false,
    error: {
      kind: 'parse',
      status: null,
      message: toUserErrorMessage({ internalCode, kind: 'parse', status: null }),
      requestId,
      details,
      internalCode,
      action: 'retry',
    },
  }
}
