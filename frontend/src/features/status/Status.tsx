import { useEffect, useMemo, useState } from 'react'
import type { ApiClient } from '../../api/client'
import type { ApiError } from '../../api/errors'
import type { ArtifactIndexItem, ArtifactsIndexResponse, GetJobResponse } from '../../api/types'
import { ErrorPanel } from '../../components/ErrorPanel'
import { loadAppState, resetToStep1, saveAppState } from '../../state/storage'

type StatusProps = { api: ApiClient }

type StatusError = { error: ApiError; retry: () => void; retryLabel: string }

function filenameFromRelPath(relPath: string): string {
  const parts = relPath.split('/').filter((p) => p.trim() !== '')
  const last = parts.length > 0 ? parts[parts.length - 1] : ''
  return last.trim() !== '' ? last : '文件'
}

function StepStatusHeader() {
  return (
    <>
      <h1>进度与下载</h1>
      <p className="lead">查看当前任务的进度，并下载生成的文件。</p>
    </>
  )
}

function JobSummaryPanel(props: { job: GetJobResponse | null; lastRefreshedAt: string | null }) {
  if (props.job === null) return null
  const latestRun = props.job.latest_run
  const statusLabel =
    props.job.status === 'succeeded'
      ? '已完成'
      : props.job.status === 'failed'
        ? '未完成'
        : props.job.status === 'running'
          ? '执行中'
          : props.job.status === 'queued'
            ? '已排队'
            : props.job.status
  return (
    <div className="panel">
      <div className="panel-body">
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, alignItems: 'baseline' }}>
          <span className="section-label" style={{ margin: 0 }}>
            当前进度
          </span>
          <div className="inline-hint">{props.lastRefreshedAt === null ? null : `上次刷新：${props.lastRefreshedAt}`}</div>
        </div>
        <div className="mono" style={{ marginTop: 10, color: 'var(--text-dim)' }}>
          状态：{statusLabel}
        </div>
        {latestRun !== null ? (
          <div className="inline-hint" style={{ marginTop: 8 }}>
            最近一次执行：{latestRun.status}
          </div>
        ) : null}
      </div>
    </div>
  )
}

function ArtifactsPanel(props: { artifacts: ArtifactsIndexResponse | null; onDownload: (item: ArtifactIndexItem) => void }) {
  if (props.artifacts === null) return null
  return (
    <div className="panel">
      <div className="panel-body">
        <span className="section-label" style={{ margin: 0 }}>
          下载文件
        </span>
        <div className="data-table-wrap" style={{ marginTop: 12, maxHeight: 360 }}>
          <table className="data-table">
            <thead>
              <tr>
                <th>文件</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {props.artifacts.artifacts.map((a, idx) => (
                <tr key={`${a.kind}_${a.rel_path}_${idx}`}>
                  <td className="mono">{filenameFromRelPath(a.rel_path)}</td>
                  <td style={{ width: 120, whiteSpace: 'nowrap' }}>
                    <button className="btn btn-secondary" type="button" style={{ height: 28 }} onClick={() => props.onDownload(a)}>
                      下载
                    </button>
                  </td>
                </tr>
              ))}
              {props.artifacts.artifacts.length === 0 ? (
                <tr>
                  <td colSpan={2} className="inline-hint">
                    暂无可下载文件
                  </td>
                </tr>
              ) : null}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}

export function Status(props: StatusProps) {
  const app = loadAppState()
  const jobId = app.jobId
  const [busy, setBusy] = useState(false)
  const [autoRefresh, setAutoRefresh] = useState(false)
  const [job, setJob] = useState<GetJobResponse | null>(null)
  const [artifacts, setArtifacts] = useState<ArtifactsIndexResponse | null>(null)
  const [lastRefreshedAt, setLastRefreshedAt] = useState<string | null>(null)
  const [actionError, setActionError] = useState<StatusError | null>(null)

  const redeem = useMemo(() => {
    return () => {
      resetToStep1()
      saveAppState({ view: 'step1' })
      window.location.reload()
    }
  }, [])

  async function refreshOnce(): Promise<void> {
    if (jobId === null || jobId.trim() === '') return

    setActionError(null)
    setBusy(true)
    try {
      const jobResp = await props.api.getJob(jobId)
      if (!jobResp.ok) {
        setActionError({ error: jobResp.error, retry: () => void refreshOnce(), retryLabel: '重试查询' })
        return
      }
      setJob(jobResp.value)

      const artifactsResp = await props.api.listArtifacts(jobId)
      if (!artifactsResp.ok) {
        setActionError({ error: artifactsResp.error, retry: () => void refreshOnce(), retryLabel: '重试查询' })
        return
      }
      setArtifacts(artifactsResp.value)
      setLastRefreshedAt(new Date().toLocaleTimeString())
    } finally {
      setBusy(false)
    }
  }

  async function download(item: ArtifactIndexItem): Promise<void> {
    if (jobId === null || jobId.trim() === '') return
    setActionError(null)
    setBusy(true)
    try {
      const result = await props.api.downloadArtifact(jobId, item.rel_path)
      if (!result.ok) {
        setActionError({ error: result.error, retry: () => void download(item), retryLabel: '重试下载' })
        return
      }
      const url = URL.createObjectURL(result.value)
      const a = document.createElement('a')
      a.href = url
      a.download = filenameFromRelPath(item.rel_path)
      a.click()
      URL.revokeObjectURL(url)
    } finally {
      setBusy(false)
    }
  }

  useEffect(() => {
    if (!autoRefresh) return
    if (jobId === null || jobId.trim() === '') return
    const t = window.setInterval(() => void refreshOnce(), 3000)
    return () => window.clearInterval(t)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [autoRefresh, jobId])

  useEffect(() => {
    if (jobId === null || jobId.trim() === '') return
    void refreshOnce()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const currentError = actionError?.error ?? null

  return (
    <div className="view-fade">
      <StepStatusHeader />
      <ErrorPanel error={currentError} onRetry={actionError?.retry} retryLabel={actionError?.retryLabel} onRedeem={redeem} />
      {jobId === null ? (
        <div className="panel">
          <div className="panel-body">
            <div style={{ fontWeight: 600, marginBottom: 6 }}>缺少任务信息</div>
            <div className="inline-hint">请先完成第一步获取任务验证码。</div>
            <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 12 }}>
              <button className="btn btn-primary" type="button" onClick={redeem}>
                返回第一步
              </button>
            </div>
          </div>
        </div>
      ) : (
        <>
          <div className="panel">
            <div className="panel-body">
              <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
                <button className="btn btn-secondary" type="button" onClick={() => setAutoRefresh((prev) => !prev)} disabled={busy}>
                  {autoRefresh ? '停止自动刷新' : '开启自动刷新'}
                </button>
                <button className="btn btn-primary" type="button" onClick={() => void refreshOnce()} disabled={busy}>
                  刷新
                </button>
              </div>
            </div>
          </div>
          <JobSummaryPanel job={job} lastRefreshedAt={lastRefreshedAt} />
          <ArtifactsPanel artifacts={artifacts} onDownload={(item) => void download(item)} />
        </>
      )}
      <div style={{ display: 'flex', justifyContent: 'flex-start', gap: 12, marginTop: 24 }}>
        <button className="btn btn-secondary" type="button" onClick={redeem} disabled={busy}>
          重新开始
        </button>
      </div>
    </div>
  )
}
