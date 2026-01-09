import { useMemo } from 'react'
import { ApiClient } from './api/client'
import { Step1 } from './features/step1/Step1'
import { Step2Placeholder } from './features/step2/Step2Placeholder'
import { useTheme } from './state/theme'
import { loadAppState } from './state/storage'

function App() {
  const { theme, toggleTheme } = useTheme()
  const state = loadAppState()
  const api = useMemo(() => new ApiClient(), [])

  return (
    <div className="app-container">
      <header>
        <div className="brand">
          <div className="brand-icon">S</div>
          Stata Service
        </div>
        <div className="tabs-container">
          <div className="tabs">
            <button className="tab active" type="button">
              分析任务
            </button>
            <button className="tab" type="button" disabled>
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

      <main>{state.view === 'step2' ? <Step2Placeholder api={api} /> : <Step1 api={api} />}</main>
    </div>
  )
}

export default App
