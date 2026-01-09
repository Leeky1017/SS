import type { ApiClient } from '../../api/client'
import { getAuthToken, loadAppState, resetToStep1, saveAppState } from '../../state/storage'

type Step2Props = { api: ApiClient }

type JobInfo = { jobId: string | null; hasToken: boolean }

function loadJobInfo(): JobInfo {
  const state = loadAppState()
  const jobId = state.jobId
  const token = jobId === null ? null : getAuthToken(jobId)
  return { jobId, hasToken: token !== null }
}

function JobPanel(props: JobInfo) {
  return (
    <div className="panel">
      <div className="panel-body">
        <span className="section-label" style={{ margin: 0 }}>
          Current job
        </span>
        <div className="mono" style={{ marginTop: 8, color: 'var(--text-dim)' }}>
          job_id: {props.jobId ?? '—'}
        </div>
        <div className="mono" style={{ marginTop: 8, color: 'var(--text-muted)' }}>
          token: {props.hasToken ? 'present' : 'absent'}
        </div>
        {!props.hasToken ? (
          <div className="inline-hint" style={{ marginTop: 10 }}>
            当前 job 没有 token（可能来自 dev fallback create job）；后续鉴权启用后建议使用 redeem 获取 token。
          </div>
        ) : null}
      </div>
    </div>
  )
}

function Step2Actions() {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, marginTop: 24 }}>
      <button
        className="btn btn-secondary"
        type="button"
        onClick={() => {
          resetToStep1()
          saveAppState({ view: 'step1' })
          window.location.reload()
        }}
      >
        重新兑换
      </button>
      <button
        className="btn btn-primary"
        type="button"
        onClick={() => {
          saveAppState({ view: 'step2' })
          window.location.reload()
        }}
      >
        刷新自测
      </button>
    </div>
  )
}

export function Step2Placeholder(props: Step2Props) {
  void props.api
  const info = loadJobInfo()

  return (
    <div className="view-fade">
      <div className="stepper">
        <div className="step-tick done" />
        <div className="step-tick active" />
        <div className="step-tick" />
      </div>

      <h1>下一步：上传数据</h1>
      <p className="lead">Step 2（上传与预览）将在 FE-C004 中落地；当前用于验证 redeem / 本地恢复链路。</p>
      <JobPanel {...info} />
      <Step2Actions />
    </div>
  )
}
