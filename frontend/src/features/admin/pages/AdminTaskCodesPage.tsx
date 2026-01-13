import { useEffect, useState } from 'react'
import type { ApiError } from '../../../api/errors'
import { ErrorPanel } from '../../../components/ErrorPanel'
import type { AdminApiClient } from '../adminApi'
import type { AdminTaskCodeItem } from '../adminApiTypes'

type AdminTaskCodesPageProps = {
  api: AdminApiClient
  tenantId: string
  tenants: string[]
  onAuthInvalid: () => void
}

type TenantFilter = '' | string

export function AdminTaskCodesPage(props: AdminTaskCodesPageProps) {
  const [busy, setBusy] = useState<boolean>(false)
  const [error, setError] = useState<ApiError | null>(null)
  const [items, setItems] = useState<AdminTaskCodeItem[]>([])

  const [count, setCount] = useState<number>(5)
  const [expiresInDays, setExpiresInDays] = useState<number>(30)
  const [createdCodes, setCreatedCodes] = useState<string[]>([])

  const [filterTenant, setFilterTenant] = useState<TenantFilter>(props.tenantId)
  const [filterStatus, setFilterStatus] = useState<string>('')

  const refresh = async () => {
    if (busy) return
    setBusy(true)
    setError(null)
    const result = await props.api.listTaskCodes({
      tenantId: filterTenant === '' ? null : filterTenant,
      status: filterStatus === '' ? null : filterStatus,
    })
    setBusy(false)

    if (!result.ok) {
      if (result.error.kind === 'unauthorized' || result.error.kind === 'forbidden') props.onAuthInvalid()
      setError(result.error)
      return
    }
    setItems(result.value.task_codes)
  }

  useEffect(() => {
    void refresh()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filterTenant, filterStatus])

  const create = async () => {
    if (busy) return
    setBusy(true)
    setError(null)
    setCreatedCodes([])
    const result = await props.api.createTaskCodes({
      tenant_id: props.tenantId,
      count,
      expires_in_days: expiresInDays,
    })
    setBusy(false)

    if (!result.ok) {
      if (result.error.kind === 'unauthorized' || result.error.kind === 'forbidden') props.onAuthInvalid()
      setError(result.error)
      return
    }
    setCreatedCodes(result.value.task_codes.map((t) => t.task_code))
    await refresh()
  }

  const revoke = async (codeId: string) => {
    if (busy) return
    setBusy(true)
    setError(null)
    const result = await props.api.revokeTaskCode(codeId)
    setBusy(false)

    if (!result.ok) {
      if (result.error.kind === 'unauthorized' || result.error.kind === 'forbidden') props.onAuthInvalid()
      setError(result.error)
      return
    }
    await refresh()
  }

  const del = async (codeId: string) => {
    if (busy) return
    if (!window.confirm(`确认删除 task code: ${codeId} ?`)) return
    setBusy(true)
    setError(null)
    const result = await props.api.deleteTaskCode(codeId)
    setBusy(false)

    if (!result.ok) {
      if (result.error.kind === 'unauthorized' || result.error.kind === 'forbidden') props.onAuthInvalid()
      setError(result.error)
      return
    }
    await refresh()
  }

  return (
    <div className="view-fade">
      <h1>Task Codes</h1>
      <div className="lead">批量创建 / 列表 / revoke / delete。Redeem 时会尽力标记 used。</div>

      <ErrorPanel error={error} onRetry={() => void refresh()} />

      <div className="panel">
        <div className="panel-body">
          <div className="section-label">CREATE</div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 12 }}>
            <div>
              <label className="section-label">tenant</label>
              <div className="mono">{props.tenantId}</div>
            </div>
            <div>
              <label className="section-label">count</label>
              <input
                type="text"
                value={String(count)}
                onChange={(e) => setCount(Number(e.target.value))}
              />
            </div>
            <div>
              <label className="section-label">expires_in_days</label>
              <input
                type="text"
                value={String(expiresInDays)}
                onChange={(e) => setExpiresInDays(Number(e.target.value))}
              />
            </div>
          </div>
          <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 12 }}>
            <button className="btn btn-primary" type="button" onClick={() => void create()} disabled={busy}>
              创建
            </button>
          </div>
          {createdCodes.length === 0 ? null : (
            <div className="panel inset-panel" style={{ marginTop: 16 }}>
              <div className="panel-body">
                <div style={{ fontWeight: 600, marginBottom: 6 }}>新 Task Codes（可复制）</div>
                <div className="mono pre-wrap">{createdCodes.join('\n')}</div>
              </div>
            </div>
          )}
        </div>
      </div>

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
                <option value="unused">unused</option>
                <option value="used">used</option>
                <option value="expired">expired</option>
                <option value="revoked">revoked</option>
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
          <div className="section-label">TASK CODES</div>
          <div className="data-table-wrap" style={{ maxHeight: 420 }}>
            <table className="data-table">
              <thead>
                <tr>
                  <th>status</th>
                  <th>tenant</th>
                  <th>task_code</th>
                  <th>expires_at</th>
                  <th>used_at</th>
                  <th>job_id</th>
                  <th>revoked_at</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {items.length === 0 ? (
                  <tr>
                    <td colSpan={8} className="inline-hint">
                      暂无记录
                    </td>
                  </tr>
                ) : (
                  items.map((t) => (
                    <tr key={t.code_id}>
                      <td style={{ fontWeight: 600 }}>{t.status}</td>
                      <td className="mono">{t.tenant_id}</td>
                      <td className="mono">{t.task_code}</td>
                      <td className="mono">{t.expires_at}</td>
                      <td className="mono">{t.used_at ?? ''}</td>
                      <td className="mono">{t.job_id ?? ''}</td>
                      <td className="mono">{t.revoked_at ?? ''}</td>
                      <td>
                        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8 }}>
                          <button
                            className="btn btn-secondary"
                            type="button"
                            disabled={busy || t.status === 'revoked'}
                            onClick={() => void revoke(t.code_id)}
                          >
                            revoke
                          </button>
                          <button className="btn btn-secondary" type="button" disabled={busy} onClick={() => void del(t.code_id)}>
                            delete
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
    </div>
  )
}

