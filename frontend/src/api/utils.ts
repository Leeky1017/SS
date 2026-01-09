export function resolveBaseUrl(override: string | undefined): string {
  const raw = override ?? (import.meta.env.VITE_API_BASE_URL as string | undefined)
  if (raw !== undefined && raw.trim() !== '') return raw.trim()
  return '/v1'
}

export function requestId(): string {
  if (typeof crypto !== 'undefined' && 'randomUUID' in crypto) {
    return crypto.randomUUID().replaceAll('-', '')
  }
  return Math.random().toString(16).slice(2) + Date.now().toString(16)
}

export async function safeJson(response: Response): Promise<unknown> {
  const text = await response.text()
  if (text.trim() === '') return null
  return JSON.parse(text)
}

export function readErrorMessage(details: unknown): string | null {
  if (details === null || details === undefined) return null
  if (typeof details === 'object') {
    const asRecord = details as Record<string, unknown>
    const message = asRecord.message
    if (typeof message === 'string' && message.trim() !== '') return message
    const detail = asRecord.detail
    if (typeof detail === 'string' && detail.trim() !== '') return detail
    const errorCode = asRecord.error_code
    if (typeof errorCode === 'string' && errorCode.trim() !== '') return errorCode
  }
  if (typeof details === 'string') return details
  return null
}

export function encodePathPreservingSlashes(path: string): string {
  const trimmed = path.startsWith('/') ? path.slice(1) : path
  return trimmed
    .split('/')
    .map((segment) => encodeURIComponent(segment))
    .join('/')
}

