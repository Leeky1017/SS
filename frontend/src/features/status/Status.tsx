import { useEffect, useMemo, useState } from 'react'
import type { ApiClient } from '../../api/client'
import type { ApiError } from '../../api/errors'
import type { ArtifactIndexItem, ArtifactsIndexResponse, GetJobResponse } from '../../api/types'
import { ErrorPanel } from '../../components/ErrorPanel'
import { loadAppState, resetToStep1, saveAppState, setLastJobId } from '../../state/storage'

type StatusProps = { api: ApiClient }

type StatusError = { error: ApiError; retry: () => void; retryLabel: string }

function filenameFromRelPath(relPath: string): string {
  const parts = relPath.split('/').filter((p) => p.trim() !== '')
  const last = parts.length > 0 ? parts[parts.length - 1] : ''
  return last.trim() !== '' ? last : 'artifact'
}

function StepStatusHeader() {
  return (
    <>
      <h1>执行查询</h1>
      <p className="lead">查询 job 状态、轮询刷新，并下载 artifacts（日志/脚本/结果）。</p>
    </>
  )
}

function JobIdPanel(props: {
  jobId: string
  polling: boolean
  busy: boolean
  onChangeJobId: (v: string) => void
  onApply: () => void
  onTogglePolling: () => void
}) {
  return (
    <div className="panel">
      <div className="panel-body">
        <span className="section-label required">job_id</span>
        <input
          type="text"
          className="mono"
          value={props.jobId}
          disabled={props.busy}
          placeholder="例如 job_0123456789abcdef"
          onChange={(e) => props.onChangeJobId(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') props.onApply()
          }}
        />
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, marginTop: 12 }}>
          <button className="btn btn-secondary" type="button" onClick={props.onTogglePolling} disabled={props.jobId.trim() === ''}>
            {props.polling ? '停止轮询' : '开始轮询'}
          </button>
          <button className="btn btn-primary" type="button" onClick={props.onApply} disabled={props.jobId.trim() === '' || props.busy}>
            刷新查询
          </button>
        </div>
      </div>
    </div>
  )
}

function JobSummaryPanel(props: { job: GetJobResponse | null; lastRefreshedAt: string | null }) {
  if (props.job === null) return null
  const latestRun = props.job.latest_run
  return (
    <div className="panel">
      <div className="panel-body">
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, alignItems: 'baseline' }}>
          <span className="section-label" style={{ margin: 0 }}>
            Job
          </span>
          <div className="inline-hint">{props.lastRefreshedAt === null ? null : `last_refresh: ${props.lastRefreshedAt}`}</div>
        </div>
        <div className="mono" style={{ marginTop: 10, color: 'var(--text-dim)' }}>
          status: {props.job.status}
        </div>
        <div className="mono" style={{ marginTop: 8, color: 'var(--text-muted)' }}>
          created_at: {props.job.timestamps.created_at}
        </div>
        {props.job.timestamps.scheduled_at !== null ? (
          <div className="mono" style={{ marginTop: 8, color: 'var(--text-muted)' }}>
            scheduled_at: {props.job.timestamps.scheduled_at}
          </div>
        ) : null}
        {props.job.draft !== null ? (
          <div className="mono" style={{ marginTop: 8, color: 'var(--text-muted)' }}>
            draft: chars={props.job.draft.text_chars} · created_at={props.job.draft.created_at}
          </div>
        ) : null}
        {latestRun !== null ? (
          <div className="mono" style={{ marginTop: 8, color: 'var(--text-muted)' }}>
            latest_run: {latestRun.run_id} · attempt={latestRun.attempt} · status={latestRun.status} · artifacts={latestRun.artifacts_count}
          </div>
        ) : null}
        <div className="mono" style={{ marginTop: 8, color: 'var(--text-muted)' }}>
          artifacts_total: {props.job.artifacts.total}
        </div>
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
          Artifacts
        </span>
        <div className="data-table-wrap" style={{ marginTop: 12, maxHeight: 360 }}>
          <table className="data-table">
            <thead>
              <tr>
                <th>Kind</th>
                <th>rel_path</th>
                <th>meta</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {props.artifacts.artifacts.map((a, idx) => (
                <tr key={`${a.kind}_${a.rel_path}_${idx}`}>
                  <td className="mono">{a.kind}</td>
                  <td className="mono">{a.rel_path}</td>
                  <td className="mono" style={{ color: 'var(--text-muted)' }}>
                    {JSON.stringify(a.meta)}
                  </td>
                  <td style={{ width: 120, whiteSpace: 'nowrap' }}>
                    <button className="btn btn-secondary" type="button" style={{ height: 28 }} onClick={() => props.onDownload(a)}>
                      下载
                    </button>
                  </td>
                </tr>
              ))}
              {props.artifacts.artifacts.length === 0 ? (
                <tr>
                  <td colSpan={4} className="inline-hint">
                    暂无 artifacts
                  </td>
                </tr>
              ) : null}
            </tbody>
          </table>
        </div>
        <div className="inline-hint" style={{ marginTop: 10 }}>
          rel_path 为 job-relative 路径；下载将请求 <span className="mono">{'/v1/jobs/{job_id}/artifacts/{rel_path}'}</span>。
        </div>
      </div>
    </div>
  )
}

export function Status(props: StatusProps) {
  const app = loadAppState()
  const [jobId, setJobId] = useState(() => (app.jobId ?? '').trim())
  const [busy, setBusy] = useState(false)
  const [polling, setPolling] = useState(false)
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
    const trimmed = jobId.trim()
    if (trimmed === '') return

    setActionError(null)
    setBusy(true)
    try {
      const jobResp = await props.api.getJob(trimmed)
      if (!jobResp.ok) {
        setActionError({ error: jobResp.error, retry: () => void refreshOnce(), retryLabel: '重试查询' })
        return
      }
      setJob(jobResp.value)

      const artifactsResp = await props.api.listArtifacts(trimmed)
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

  async function applyJobId(): Promise<void> {
    const trimmed = jobId.trim()
    if (trimmed === '') return
    setLastJobId(trimmed)
    saveAppState({ jobId: trimmed, view: 'status' })
    await refreshOnce()
  }

  async function download(item: ArtifactIndexItem): Promise<void> {
    const trimmed = jobId.trim()
    if (trimmed === '') return
    setActionError(null)
    setBusy(true)
    try {
      const result = await props.api.downloadArtifact(trimmed, item.rel_path)
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
    if (!polling) return
    if (jobId.trim() === '') return
    const t = window.setInterval(() => void refreshOnce(), 3000)
    return () => window.clearInterval(t)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [polling, jobId])

  useEffect(() => {
    if (jobId.trim() === '') return
    void refreshOnce()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const currentError = actionError?.error ?? null

  return (
    <div className="view-fade">
      <StepStatusHeader />
      <ErrorPanel error={currentError} onRetry={actionError?.retry} retryLabel={actionError?.retryLabel} onRedeem={redeem} />

      <JobIdPanel
        jobId={jobId}
        polling={polling}
        busy={busy}
        onChangeJobId={(v) => setJobId(v)}
        onApply={() => void applyJobId()}
        onTogglePolling={() => setPolling((prev) => !prev)}
      />
      <JobSummaryPanel job={job} lastRefreshedAt={lastRefreshedAt} />
      <ArtifactsPanel artifacts={artifacts} onDownload={(item) => void download(item)} />

      <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, marginTop: 24 }}>
        <button className="btn btn-secondary" type="button" onClick={redeem} disabled={busy}>
          重新兑换
        </button>
        <button className="btn btn-secondary" type="button" onClick={() => void applyJobId()} disabled={busy || jobId.trim() === ''}>
          手动刷新
        </button>
      </div>
    </div>
  )
}
