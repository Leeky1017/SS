import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App.tsx'
import { AdminApp } from './features/admin/AdminApp.tsx'

import './styles/theme.css'
import './styles/layout.css'
import './styles/components.css'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    {window.location.pathname === '/admin' || window.location.pathname.startsWith('/admin/') ? <AdminApp /> : <App />}
  </StrictMode>,
)
