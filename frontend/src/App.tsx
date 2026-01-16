import { Outlet, useMatch, useNavigate, useParams } from 'react-router-dom'
import { useTheme } from './state/theme'

function normalizeJobId(value: string | undefined): string | null {
  if (value === undefined) return null
  const trimmed = value.trim()
  return trimmed !== '' ? trimmed : null
}

function jobPath(jobId: string, suffix: string): string {
  return `/jobs/${encodeURIComponent(jobId)}/${suffix}`
}

function App() {
  const { theme, toggleTheme } = useTheme()
  const navigate = useNavigate()
  const jobId = normalizeJobId(useParams().jobId)
  const isStatusView = useMatch('/jobs/:jobId/status') !== null

  return (
    <div className="app-container">
      <header>
        <div className="brand">
          <div className="brand-icon">S</div>
          Stata Service
        </div>
        <div className="tabs-container">
          <div className="tabs">
            <button
              className={`tab${!isStatusView ? ' active' : ''}`}
              type="button"
              onClick={() => {
                if (jobId === null) navigate('/new')
                else navigate(jobPath(jobId, 'upload'))
              }}
            >
              分析任务
            </button>
            <button
              className={`tab${isStatusView ? ' active' : ''}`}
              type="button"
              onClick={() => {
                if (jobId === null) navigate('/new')
                else navigate(jobPath(jobId, 'status'))
              }}
            >
              执行查询
            </button>
          </div>
        </div>
        <div className="header-actions">
          <button
            className="theme-toggle"
            type="button"
            aria-label="切换主题"
            title="切换主题"
            onClick={toggleTheme}
          >
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

      <main>
        <Outlet />
      </main>
    </div>
  )
}

export default App
