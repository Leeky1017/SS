import { useEffect, useMemo, useState } from 'react'
import type { ApiError } from '../../../api/errors'
import { ErrorPanel } from '../../../components/ErrorPanel'
import type { AdminApiClient } from '../adminApi'
import type { AdminArtifactItem, AdminJobDetailResponse, AdminJobListItem } from '../adminApiTypes'
import { AdminJobDetailPanel } from './AdminJobDetailPanel'

type AdminJobsPageProps = {
  api: AdminApiClient
  tenants: string[]
  onAuthInvalid: () => void
}

type TenantFilter = '' | string

export function AdminJobsPage(props: AdminJobsPageProps) {
  const [busy, setBusy] = useState<boolean>(false)
  const [error, setError] = useState<ApiError | null>(null)
  const [items, setItems] = useState<AdminJobListItem[]>([])

  const [filterTenant, setFilterTenant] = useState<TenantFilter>('')
  const [filterStatus, setFilterStatus] = useState<string>('')

  const [selected, setSelected] = useState<AdminJobListItem | null>(null)
  const [detail, setDetail] = useState<AdminJobDetailResponse | null>(null)

  const refresh = async () => {
    if (busy) return
    setBusy(true)
    setError(null)
    const result = await props.api.listJobs({
      tenantId: filterTenant === '' ? null : filterTenant,
      status: filterStatus === '' ? null : filterStatus,
    })
    setBusy(false)

    if (!result.ok) {
      if (result.error.kind === 'unauthorized' || result.error.kind === 'forbidden') props.onAuthInvalid()
      setError(result.error)
      return
    }
    setItems(result.value.jobs)
  }

  const loadDetail = async (job: AdminJobListItem) => {
    if (busy) return
    setSelected(job)
    setDetail(null)
    setBusy(true)
    setError(null)
    const result = await props.api.getJobDetail(job.job_id, job.tenant_id)
    setBusy(false)

    if (!result.ok) {
      if (result.error.kind === 'unauthorized' || result.error.kind === 'forbidden') props.onAuthInvalid()
      setError(result.error)
      return
    }
    setDetail(result.value)
  }

  useEffect(() => {
    void refresh()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filterTenant, filterStatus])

  const statusOptions = useMemo(() => {
    return ['', 'created', 'queued', 'running', 'failed', 'succeeded', 'completed']
  }, [])

  const downloadArtifact = async (jobId: string, tenantId: string, item: AdminArtifactItem) => {
    const result = await props.api.downloadJobArtifact(jobId, item.rel_path, tenantId)
    if (!result.ok) {
      if (result.error.kind === 'unauthorized' || result.error.kind === 'forbidden') props.onAuthInvalid()
      setError(result.error)
      return
    }
    const blobUrl = URL.createObjectURL(result.value)
    const a = document.createElement('a')
    a.href = blobUrl
    a.download = item.rel_path.split('/').pop() ?? 'artifact'
    document.body.appendChild(a)
    a.click()
    a.remove()
    URL.revokeObjectURL(blobUrl)
  }

  const retrySelected = async () => {
    if (selected === null) return
    setBusy(true)
    setError(null)
    const result = await props.api.retryJob(selected.job_id, selected.tenant_id)
    setBusy(false)

    if (!result.ok) {
      if (result.error.kind === 'unauthorized' || result.error.kind === 'forbidden') props.onAuthInvalid()
      setError(result.error)
      return
    }
    await refresh()
    await loadDetail(selected)
  }

  return (
    <div className="view-fade">
      <h1>Jobs</h1>
      <div className="lead">全量 Job 列表 / 详情 / 重试 / 下载产物。</div>

      <ErrorPanel error={error} onRetry={() => void refresh()} />

      <div className="panel">
        <div className="panel-body">
          <div className="section-label">FILTER</div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12, alignItems: 'end' }}>
            <div>
              <label className="section-label">tenant</label>
              <select value={filterTenant} onChange={(e) => setFilterTenant(e.target.value)}>
                <option value="">(all)</option>
                {props.tenants.map((t) => (
                  <option key={t} value={t}>
                    {t}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="section-label">status</label>
              <select value={filterStatus} onChange={(e) => setFilterStatus(e.target.value)}>
                <option value="">(all)</option>
                {statusOptions
                  .filter((s) => s !== '')
                  .map((s) => (
                    <option key={s} value={s}>
                      {s}
                    </option>
                  ))}
              </select>
            </div>
            <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
              <button className="btn btn-secondary" type="button" onClick={() => void refresh()} disabled={busy}>
                {busy ? '刷新中…' : '刷新'}
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="panel">
        <div className="panel-body">
          <div className="section-label">JOBS</div>
          <div className="data-table-wrap" style={{ maxHeight: 420 }}>
            <table className="data-table">
              <thead>
                <tr>
                  <th>tenant</th>
                  <th>job_id</th>
                  <th>status</th>
                  <th>created_at</th>
                  <th>updated_at</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {items.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="inline-hint">
                      暂无记录
                    </td>
                  </tr>
                ) : (
                  items.map((j) => (
                    <tr key={`${j.tenant_id}:${j.job_id}`}>
                      <td className="mono">{j.tenant_id}</td>
                      <td className="mono">{j.job_id}</td>
                      <td style={{ fontWeight: 600 }}>{j.status}</td>
                      <td className="mono">{j.created_at}</td>
                      <td className="mono">{j.updated_at ?? ''}</td>
                      <td>
                        <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
                          <button className="btn btn-secondary" type="button" onClick={() => void loadDetail(j)} disabled={busy}>
                            详情
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {detail === null ? null : (
        <AdminJobDetailPanel
          detail={detail}
          busy={busy}
          onRetry={() => void retrySelected()}
          onDownloadArtifact={(artifact) => void downloadArtifact(detail.job_id, detail.tenant_id, artifact)}
        />
      )}
    </div>
  )
}
