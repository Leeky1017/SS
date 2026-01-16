import { useEffect, useMemo, useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import type { ApiError } from '../../api/errors'
import { ErrorPanel } from '../../components/ErrorPanel'
import { useTheme } from '../../state/theme'
import { AdminApiClient } from './adminApi'
import { loadAdminTenantId, loadAdminToken, saveAdminTenantId, saveAdminToken, clearAdminToken } from './adminStorage'
import { AdminJobsPage } from './pages/AdminJobsPage'
import { AdminSystemPage } from './pages/AdminSystemPage'
import { AdminTaskCodesPage } from './pages/AdminTaskCodesPage'
import { AdminTokensPage } from './pages/AdminTokensPage'

type AdminView = 'system' | 'jobs' | 'task-codes' | 'tokens'

function adminViewFromPathname(pathname: string): AdminView {
  const trimmed = pathname.replace(/^\/admin\/?/, '')
  const first = trimmed.split('/').filter((p) => p.trim() !== '')[0] ?? ''
  if (first === 'jobs') return 'jobs'
  if (first === 'task-codes') return 'task-codes'
  if (first === 'tokens') return 'tokens'
  return 'system'
}

export function AdminApp() {
  const api = useMemo(() => new AdminApiClient(), [])
  const { theme, toggleTheme } = useTheme()
  const navigate = useNavigate()
  const location = useLocation()

  const [token, setToken] = useState<string | null>(() => loadAdminToken())
  const view = useMemo(() => adminViewFromPathname(location.pathname), [location.pathname])
  const [tenantId, setTenantId] = useState<string>(() => loadAdminTenantId())
  const [tenants, setTenants] = useState<string[]>([tenantId])

  const [loginUsername, setLoginUsername] = useState<string>('admin')
  const [loginPassword, setLoginPassword] = useState<string>('')
  const [loginBusy, setLoginBusy] = useState<boolean>(false)
  const [loginError, setLoginError] = useState<ApiError | null>(null)

  const onAuthInvalid = () => {
    clearAdminToken()
    setToken(null)
  }

  useEffect(() => {
    if (token === null) return
    const run = async () => {
      const result = await api.listTenants()
      if (!result.ok) {
        if (result.error.kind === 'unauthorized' || result.error.kind === 'forbidden') onAuthInvalid()
        return
      }
      const items = result.value.tenants ?? []
      setTenants(items.length > 0 ? items : ['default'])
    }
    void run()
  }, [api, token])

  if (token === null) {
    return (
      <div className="app-container">
        <header>
          <div className="brand">
            <div className="brand-icon">S</div>
            SS 管理后台
          </div>
          <div />
          <div className="header-actions">
            <button className="theme-toggle" type="button" aria-label="切换主题" title="切换主题" onClick={toggleTheme}>
              {theme === 'dark' ? (
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M12 18a6 6 0 1 1 0-12 6 6 0 0 1 0 12Z" />
                </svg>
              ) : (
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
                </svg>
              )}
            </button>
          </div>
        </header>

        <main className="admin-main">
          <h1>管理员登录</h1>
          <div className="lead">请输入管理员账号密码登录。</div>

          <ErrorPanel
            error={loginError}
            onRetry={() => void handleLogin()}
            retryLabel="重试登录"
          />

          <div className="panel">
            <div className="panel-body">
              <div className="control-group">
                <label className="section-label">用户名</label>
                <input type="text" value={loginUsername} onChange={(e) => setLoginUsername(e.target.value)} />
              </div>
              <div className="control-group">
                <label className="section-label">密码</label>
                <input
                  type="password"
                  value={loginPassword}
                  onChange={(e) => setLoginPassword(e.target.value)}
                />
                <div className="inline-hint" style={{ marginTop: 8 }}>
                  如无法登录，请联系支持。
                </div>
              </div>
              <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
                <button
                  className="btn btn-primary"
                  type="button"
                  disabled={loginBusy || loginUsername.trim() === '' || loginPassword.trim() === ''}
                  onClick={() => void handleLogin()}
                >
                  {loginBusy ? '登录中…' : '登录'}
                </button>
              </div>
            </div>
          </div>
        </main>
      </div>
    )
  }

  const logout = async () => {
    await api.logout()
    onAuthInvalid()
  }

  const currentTenantOptions = tenants.length > 0 ? tenants : ['default']

  return (
    <div className="app-container">
      <header>
        <div className="brand">
          <div className="brand-icon">S</div>
          SS 管理后台
        </div>
        <div className="tabs-container">
          <div className="tabs">
            <button className={`tab${view === 'system' ? ' active' : ''}`} type="button" onClick={() => navigate('/admin/system')}>
              系统状态
            </button>
            <button className={`tab${view === 'jobs' ? ' active' : ''}`} type="button" onClick={() => navigate('/admin/jobs')}>
              任务
            </button>
            <button className={`tab${view === 'task-codes' ? ' active' : ''}`} type="button" onClick={() => navigate('/admin/task-codes')}>
              验证码
            </button>
            <button className={`tab${view === 'tokens' ? ' active' : ''}`} type="button" onClick={() => navigate('/admin/tokens')}>
              访问凭证
            </button>
          </div>
        </div>
        <div className="header-actions">
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <select
              value={tenantId}
              onChange={(e) => {
                const next = e.target.value
                setTenantId(next)
                saveAdminTenantId(next)
              }}
              style={{ width: 180 }}
            >
              {currentTenantOptions.map((t) => (
                <option key={t} value={t}>
                  {t}
                </option>
              ))}
            </select>
            <button className="btn btn-secondary" type="button" onClick={() => void logout()}>
              登出
            </button>
          </div>
          <button className="theme-toggle" type="button" aria-label="切换主题" title="切换主题" onClick={toggleTheme}>
            {theme === 'dark' ? (
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M12 18a6 6 0 1 1 0-12 6 6 0 0 1 0 12Z" />
              </svg>
            ) : (
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
              </svg>
            )}
          </button>
        </div>
      </header>

      <main className="admin-main">
        {view === 'tokens' ? (
          <AdminTokensPage api={api} onAuthInvalid={onAuthInvalid} />
        ) : view === 'task-codes' ? (
          <AdminTaskCodesPage
            api={api}
            tenantId={tenantId}
            tenants={currentTenantOptions}
            onAuthInvalid={onAuthInvalid}
          />
        ) : view === 'jobs' ? (
          <AdminJobsPage api={api} tenants={currentTenantOptions} onAuthInvalid={onAuthInvalid} />
        ) : (
          <AdminSystemPage api={api} onAuthInvalid={onAuthInvalid} />
        )}
      </main>
    </div>
  )

  async function handleLogin(): Promise<void> {
    if (loginBusy) return
    setLoginBusy(true)
    setLoginError(null)
    const result = await api.login({ username: loginUsername, password: loginPassword })
    setLoginBusy(false)

    if (!result.ok) {
      setLoginError(result.error)
      return
    }
    saveAdminToken(result.value.token)
    setToken(result.value.token)
    setLoginPassword('')
  }
}
