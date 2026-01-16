import { useEffect, useState } from 'react'
import type { ApiError } from '../../../api/errors'
import { ErrorPanel } from '../../../components/ErrorPanel'
import type { AdminSystemStatusResponse } from '../adminApiTypes'
import type { AdminApiClient } from '../adminApi'

type AdminSystemPageProps = {
  api: AdminApiClient
  onAuthInvalid: () => void
}

type HealthCheckItem = NonNullable<AdminSystemStatusResponse['health']['checks']>[string]

function healthStatusLabel(status: string): string {
  return status === 'ok' ? '正常' : '异常'
}

function checkLabel(name: string): string {
  const labels: Record<string, string> = {
    shutting_down: '运行状态',
    jobs_dir: '任务目录',
    queue_dir: '排队目录',
    llm: '分析服务',
    production_mode: '运行模式',
    prod_llm: '生产环境分析服务',
    prod_runner: '生产环境执行引擎',
    prod_upload_object_store: '生产环境上传服务',
  }
  return labels[name] ?? '系统检查'
}

function checkDetail(name: string, item: HealthCheckItem): string {
  if (item.ok) {
    if (name === 'production_mode' && item.detail != null && item.detail.trim() !== '') {
      return item.detail === 'production' ? '生产环境' : '非生产环境'
    }
    if (name === 'shutting_down') return '运行中'
    return '正常'
  }

  if (name === 'shutting_down') return '系统正在关闭中'
  if (name === 'jobs_dir' || name === 'queue_dir') return '目录不可用或权限不足'
  if (name === 'prod_llm') return '分析服务未就绪，请检查配置'
  if (name === 'prod_runner') return '执行引擎未就绪，请检查配置'
  if (name === 'prod_upload_object_store') return '上传服务未就绪，请检查配置'
  return '检查未通过'
}

export function AdminSystemPage(props: AdminSystemPageProps) {
  const [busy, setBusy] = useState<boolean>(false)
  const [error, setError] = useState<ApiError | null>(null)
  const [data, setData] = useState<AdminSystemStatusResponse | null>(null)
  const checks: Record<string, HealthCheckItem> = data?.health.checks ?? {}
  const workers = data?.workers ?? []

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
      <div className="lead">健康检查与运行概况。</div>

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
                  <div className="section-label">检查时间</div>
                  <div className="mono">{data.checked_at}</div>
                </div>
                <div>
                  <div className="section-label">状态</div>
                  <div style={{ fontWeight: 600 }}>{healthStatusLabel(data.health.status)}</div>
                </div>
                <div>
                  <div className="section-label">待处理</div>
                  <div className="mono">
                    待处理：{data.queue.queued} · 处理中：{data.queue.claimed}
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div className="panel">
            <div className="panel-body">
              <div className="section-label">检查项</div>
              <div className="data-table-wrap">
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>名称</th>
                      <th>是否正常</th>
                      <th>说明</th>
                    </tr>
                  </thead>
                  <tbody>
                    {Object.entries(checks).map(([name, item]) => (
                      <tr key={name}>
                        <td>{checkLabel(name)}</td>
                        <td style={{ fontWeight: 600, color: item.ok ? 'var(--success)' : 'var(--error)' }}>
                          {item.ok ? '正常' : '异常'}
                        </td>
                        <td className="pre-wrap">{checkDetail(name, item)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div className="panel">
            <div className="panel-body">
              <div className="section-label">执行进程</div>
              {workers.length === 0 ? (
                <div className="inline-hint">暂无活跃记录。</div>
              ) : (
                <div className="data-table-wrap">
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>标识</th>
                        <th>当前任务数</th>
                        <th>最近开始</th>
                        <th>最近截止</th>
                      </tr>
                    </thead>
                    <tbody>
                      {workers.map((w) => (
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
