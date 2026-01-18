import { useMemo } from 'react'
import { BrowserRouter, Navigate, Route, Routes, useParams } from 'react-router-dom'
import App from './App'
import { ApiClient } from './api/client'
import { AdminApp } from './features/admin/AdminApp'
import { Step1 } from './features/step1/Step1'
import { Step2 } from './features/step2/Step2'
import { Step3 } from './features/step3/Step3'
import { Status } from './features/status/Status'
import { loadConfirmLock, loadDraftPreviewSnapshot } from './state/storage'

function JobAutoRoute() {
  const jobId = useParams().jobId ?? null
  if (jobId === null || jobId.trim() === '') return <Navigate to="/new" replace />
  if (loadConfirmLock(jobId) !== null) return <Navigate to={`/jobs/${encodeURIComponent(jobId)}/status`} replace />
  if (loadDraftPreviewSnapshot(jobId) !== null) return <Navigate to={`/jobs/${encodeURIComponent(jobId)}/preview`} replace />
  return <Navigate to={`/jobs/${encodeURIComponent(jobId)}/upload`} replace />
}

export function RootRouter() {
  const api = useMemo(() => new ApiClient(), [])
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/admin/*" element={<AdminApp />} />

        <Route path="/" element={<App api={api} />}>
          <Route index element={<Navigate to="/new" replace />} />
          <Route path="new" element={<Step1 api={api} />} />
          <Route path="jobs/:jobId" element={<JobAutoRoute />} />
          <Route path="jobs/:jobId/upload" element={<Step2 api={api} />} />
          <Route path="jobs/:jobId/preview" element={<Step3 api={api} />} />
          <Route path="jobs/:jobId/status" element={<Status api={api} />} />
          <Route path="*" element={<Navigate to="/new" replace />} />
        </Route>

        <Route path="*" element={<Navigate to="/new" replace />} />
      </Routes>
    </BrowserRouter>
  )
}
