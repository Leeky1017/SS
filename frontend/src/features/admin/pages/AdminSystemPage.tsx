import { useEffect, useState } from 'react'
import type { ApiError } from '../../../api/errors'
import { ErrorPanel } from '../../../components/ErrorPanel'
import type { AdminSystemStatusResponse } from '../adminApiTypes'
import type { AdminApiClient } from '../adminApi'

type AdminSystemPageProps = {
  api: AdminApiClient
  onAuthInvalid: () => void
}

export function AdminSystemPage(props: AdminSystemPageProps) {
  const [busy, setBusy] = useState<boolean>(false)
  const [error, setError] = useState<ApiError | null>(null)
  const [data, setData] = useState<AdminSystemStatusResponse | null>(null)

  const refresh = async () => {
    if (busy) return
    setBusy(true)
    setError(null)
    const result = await props.api.getSystemStatus()
    setBusy(false)

    if (!result.ok) {
      if (result.error.kind === 'unauthorized' || result.error.kind === 'forbidden') props.onAuthInvalid()
      setError(result.error)
      return
    }
    setData(result.value)
  }

  useEffect(() => {
    void refresh()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return (
    <div className="view-fade">
      <h1>系统状态</h1>
      <div className="lead">健康检查、队列深度、Worker 运行状态。</div>

      <ErrorPanel error={error} onRetry={() => void refresh()} />

      <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 16 }}>
        <button className="btn btn-secondary" type="button" onClick={() => void refresh()} disabled={busy}>
          {busy ? '刷新中…' : '刷新'}
        </button>
      </div>

      {data === null ? null : (
        <>
          <div className="panel">
            <div className="panel-body">
              <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, flexWrap: 'wrap' }}>
                <div>
                  <div className="section-label">CHECKED AT</div>
                  <div className="mono">{data.checked_at}</div>
                </div>
                <div>
                  <div className="section-label">STATUS</div>
                  <div style={{ fontWeight: 600 }}>{data.health.status}</div>
                </div>
                <div>
                  <div className="section-label">QUEUE</div>
                  <div className="mono">
                    queued={data.queue.queued} claimed={data.queue.claimed}
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div className="panel">
            <div className="panel-body">
              <div className="section-label">HEALTH CHECKS</div>
              <div className="data-table-wrap">
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>name</th>
                      <th>ok</th>
                      <th>detail</th>
                    </tr>
                  </thead>
                  <tbody>
                    {Object.entries(data.health.checks).map(([name, item]) => (
                      <tr key={name}>
                        <td className="mono">{name}</td>
                        <td style={{ fontWeight: 600, color: item.ok ? 'var(--success)' : 'var(--error)' }}>
                          {item.ok ? 'OK' : 'FAIL'}
                        </td>
                        <td className="pre-wrap">{item.detail ?? ''}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div className="panel">
            <div className="panel-body">
              <div className="section-label">WORKERS</div>
              {data.workers.length === 0 ? (
                <div className="inline-hint">暂无活跃 worker 记录。</div>
              ) : (
                <div className="data-table-wrap">
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>worker_id</th>
                        <th>active_claims</th>
                        <th>latest_claimed_at</th>
                        <th>latest_lease_expires_at</th>
                      </tr>
                    </thead>
                    <tbody>
                      {data.workers.map((w) => (
                        <tr key={w.worker_id}>
                          <td className="mono">{w.worker_id}</td>
                          <td className="mono">{w.active_claims}</td>
                          <td className="mono">{w.latest_claimed_at ?? ''}</td>
                          <td className="mono">{w.latest_lease_expires_at ?? ''}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>
        </>
      )}
    </div>
  )
}

