import type { ConfirmLockState } from '../../state/storage'
import type { DraftPreviewReadyResponse } from '../../api/types'

export function Step3Header() {
  return (
    <>
      <div className="stepper">
        <div className="step-tick done" />
        <div className="step-tick done" />
        <div className="step-tick active" />
      </div>
      <h1>分析蓝图预检</h1>
      <p className="lead">确认变量映射、查看风险提示并完成必要澄清；确认后将锁定并进入执行阶段。</p>
    </>
  )
}

export function LockedBanner(props: { lock: ConfirmLockState | null }) {
  if (props.lock === null) return null
  return (
    <div className="panel">
      <div className="panel-body">
        <div style={{ fontWeight: 600, marginBottom: 6 }}>已锁定（已确认）</div>
        <div className="inline-hint">confirmed_at: {props.lock.confirmedAt}</div>
      </div>
    </div>
  )
}

export function PendingPanel(props: { message: string | null; retryAfterSeconds: number }) {
  return (
    <div className="panel">
      <div className="panel-body">
        <div style={{ fontWeight: 600, marginBottom: 6 }}>预处理中…</div>
        <div className="inline-hint">{props.message ?? '后端正在生成蓝图预览，请稍后自动重试。'}</div>
        <div className="mono" style={{ marginTop: 10, color: 'var(--text-muted)' }}>
          retry_after_seconds: {props.retryAfterSeconds}
        </div>
      </div>
    </div>
  )
}

export function VariablesTable(props: { draft: DraftPreviewReadyResponse; applyCorrection: (v: string | null) => string | null }) {
  const outcome = props.applyCorrection(props.draft.outcome_var)
  const treatment = props.applyCorrection(props.draft.treatment_var)
  const controls = props.draft.controls.map((v) => props.applyCorrection(v) ?? '—')

  return (
    <div className="panel">
      <div className="panel-body">
        <span className="section-label" style={{ margin: 0 }}>
          Variables
        </span>
        <div className="data-table-wrap" style={{ marginTop: 12 }}>
          <table className="data-table">
            <thead>
              <tr>
                <th>Role</th>
                <th>Variable</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td className="mono">OUTCOME</td>
                <td>{outcome ?? '—'}</td>
              </tr>
              <tr>
                <td className="mono">TREATMENT</td>
                <td>{treatment ?? '—'}</td>
              </tr>
              <tr>
                <td className="mono">CONTROLS</td>
                <td>{controls.length > 0 ? controls.join(', ') : '—'}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}

export function WarningsPanel(props: { warnings: DraftPreviewReadyResponse['data_quality_warnings'] }) {
  const warnings = props.warnings
  if (warnings === undefined || warnings.length === 0) return null
  return (
    <div className="panel">
      <div className="panel-body">
        <span className="section-label" style={{ margin: 0 }}>
          Warnings
        </span>
        <div className="data-table-wrap" style={{ marginTop: 12, maxHeight: 220 }}>
          <table className="data-table">
            <thead>
              <tr>
                <th>Severity</th>
                <th>Message</th>
                <th>Suggestion</th>
              </tr>
            </thead>
            <tbody>
              {warnings.map((w, idx) => (
                <tr key={idx}>
                  <td className="mono">{w.severity}</td>
                  <td>{w.message}</td>
                  <td>{w.suggestion ?? '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}

export function DraftTextPanel(props: { draftText: string }) {
  return (
    <div className="panel">
      <div className="panel-body">
        <span className="section-label" style={{ margin: 0 }}>
          Draft text
        </span>
        <pre className="mono pre-wrap" style={{ marginTop: 12 }}>
          {props.draftText}
        </pre>
      </div>
    </div>
  )
}

