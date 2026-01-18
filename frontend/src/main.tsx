import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { AppErrorBoundary } from './components/AppErrorBoundary.tsx'
import { RootRouter } from './RootRouter'

import './styles/theme.css'
import './styles/layout.css'
import './styles/components.css'
import './styles/ux-wave2.css'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <AppErrorBoundary>
      <RootRouter />
    </AppErrorBoundary>
  </StrictMode>,
)
