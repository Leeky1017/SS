import { useEffect, useState } from 'react'
import { Outlet, useMatch, useNavigate, useParams } from 'react-router-dom'
import type { ApiClient } from './api/client'
import { useTheme } from './state/theme'

function normalizeJobId(value: string | undefined): string | null {
  if (value === undefined) return null
  const trimmed = value.trim()
  return trimmed !== '' ? trimmed : null
}

function jobPath(jobId: string, suffix: string): string {
  return `/jobs/${encodeURIComponent(jobId)}/${suffix}`
}

type AppProps = { api: ApiClient }

function useGlobalBusy(api: ApiClient): boolean {
  const [inFlight, setInFlight] = useState(() => api.getInFlightCount())
  const [showBusy, setShowBusy] = useState(false)
  const isBusy = inFlight > 0

  useEffect(() => api.subscribeInFlight(() => setInFlight(api.getInFlightCount())), [api])

  useEffect(() => {
    const delayMs = isBusy ? 300 : 0
    const t = window.setTimeout(() => setShowBusy(isBusy), delayMs)
    return () => window.clearTimeout(t)
  }, [isBusy])

  return showBusy
}

function ThemeIcon(props: { theme: 'dark' | 'light' }) {
  return props.theme === 'dark' ? (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
      <path d="M12 18a6 6 0 1 1 0-12 6 6 0 0 1 0 12Z" />
    </svg>
  ) : (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
      <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
    </svg>
  )
}

function AppTabs(props: { jobId: string | null; isStatusView: boolean; showBusy: boolean; onGoAnalysis: () => void; onGoStatus: () => void }) {
  return (
    <div className="tabs">
      <button className={`tab${!props.isStatusView ? ' active' : ''}`} type="button" onClick={props.onGoAnalysis}>
        分析任务{props.showBusy && !props.isStatusView ? <span className="tab-busy-indicator" aria-hidden="true" /> : null}
      </button>
      <button className={`tab${props.isStatusView ? ' active' : ''}`} type="button" onClick={props.onGoStatus}>
        执行查询{props.showBusy && props.isStatusView ? <span className="tab-busy-indicator" aria-hidden="true" /> : null}
      </button>
    </div>
  )
}

function AppHeader(props: {
  jobId: string | null
  isStatusView: boolean
  showBusy: boolean
  theme: 'dark' | 'light'
  onToggleTheme: () => void
  onGoAnalysis: () => void
  onGoStatus: () => void
}) {
  return (
    <header className={props.showBusy ? 'busy' : undefined}>
      <div className="brand">
        <div className="brand-icon">S</div>
        Stata Service
      </div>
      <div className="tabs-container">
        <AppTabs
          jobId={props.jobId}
          isStatusView={props.isStatusView}
          showBusy={props.showBusy}
          onGoAnalysis={props.onGoAnalysis}
          onGoStatus={props.onGoStatus}
        />
      </div>
      <div className="header-actions">
        <button
          className="theme-toggle"
          type="button"
          aria-label="切换主题"
          title="切换主题"
          onClick={props.onToggleTheme}
        >
          <ThemeIcon theme={props.theme} />
        </button>
      </div>
    </header>
  )
}

function App(props: AppProps) {
  const { theme, toggleTheme } = useTheme()
  const navigate = useNavigate()
  const jobId = normalizeJobId(useParams().jobId)
  const isStatusView = useMatch('/jobs/:jobId/status') !== null
  const showBusy = useGlobalBusy(props.api)

  return (
    <div className="app-container">
      <AppHeader
        jobId={jobId}
        isStatusView={isStatusView}
        showBusy={showBusy}
        theme={theme}
        onToggleTheme={toggleTheme}
        onGoAnalysis={() => (jobId === null ? navigate('/new') : navigate(jobPath(jobId, 'upload')))}
        onGoStatus={() => (jobId === null ? navigate('/new') : navigate(jobPath(jobId, 'status')))}
      />

      <main>
        <Outlet />
      </main>
    </div>
  )
}

export default App
