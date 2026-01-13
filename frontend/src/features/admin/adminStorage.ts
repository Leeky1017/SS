export type AdminSession = { token: string }

const ADMIN_TOKEN_KEY = 'ss.admin.token'
const ADMIN_TENANT_KEY = 'ss.admin.tenant_id'

export function loadAdminToken(): string | null {
  const raw = localStorage.getItem(ADMIN_TOKEN_KEY)
  if (raw === null) return null
  const token = raw.trim()
  return token === '' ? null : token
}

export function saveAdminToken(token: string): void {
  localStorage.setItem(ADMIN_TOKEN_KEY, token)
}

export function clearAdminToken(): void {
  localStorage.removeItem(ADMIN_TOKEN_KEY)
}

export function loadAdminTenantId(): string {
  const raw = localStorage.getItem(ADMIN_TENANT_KEY)
  if (raw === null) return 'default'
  const tenantId = raw.trim()
  return tenantId === '' ? 'default' : tenantId
}

export function saveAdminTenantId(tenantId: string): void {
  localStorage.setItem(ADMIN_TENANT_KEY, tenantId)
}

