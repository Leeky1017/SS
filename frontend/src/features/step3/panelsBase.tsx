import type { ConfirmLockState } from '../../state/storage'
import type { DraftPreviewReadyResponse } from '../../api/types'
import { Stepper } from '../../components/Stepper'
import { zhCN } from '../../i18n/zh-CN'

export function Step3Header(props: { onGoToStep2?: () => void } = {}) {
  return (
    <>
      <Stepper
        steps={[
          { label: '填写需求', state: 'done' },
          { label: '上传预览', state: 'done', onClick: props.onGoToStep2 },
          { label: '确认执行', state: 'active' },
        ]}
      />
      <h1>{zhCN.step3.title}</h1>
      <p className="lead">{zhCN.step3.lead}</p>
    </>
  )
}

export function LockedBanner(props: { lock: ConfirmLockState | null }) {
  if (props.lock === null) return null
  return (
    <div className="panel">
      <div className="panel-body">
        <div style={{ fontWeight: 600, marginBottom: 6 }}>{zhCN.step3.lockedTitle}</div>
        <div className="inline-hint">
          {zhCN.step3.confirmedAtLabel}: {props.lock.confirmedAt}
        </div>
      </div>
    </div>
  )
}

export function PendingPanel(props: { message: string | null; retryAfterSeconds: number }) {
  return (
    <div className="panel">
      <div className="panel-body">
        <div style={{ fontWeight: 600, marginBottom: 6 }}>{zhCN.step3.pendingTitle}</div>
        <div className="inline-hint">{props.message ?? zhCN.step3.pendingDefaultMessage}</div>
        <div className="mono" style={{ marginTop: 10, color: 'var(--text-muted)' }}>
          {zhCN.step3.retryAfterSecondsLabel}: {props.retryAfterSeconds}
        </div>
      </div>
    </div>
  )
}

export function DraftSkeletonPanel() {
  return (
    <div className="panel">
      <div className="panel-body">
        <span className="section-label" style={{ margin: 0 }}>
          {zhCN.step3.title}
        </span>
        <div style={{ display: 'grid', gap: 10, marginTop: 12 }}>
          <div className="skeleton" style={{ height: 12, width: '45%' }} />
          <div className="skeleton" style={{ height: 140, borderRadius: 8 }} />
          <div className="skeleton" style={{ height: 220, borderRadius: 8 }} />
        </div>
      </div>
    </div>
  )
}

export function VariablesTable(props: { draft: DraftPreviewReadyResponse; applyCorrection: (v: string | null) => string | null }) {
  const placeholderDash = zhCN.common.placeholderDash
  const outcome = props.applyCorrection(props.draft.outcome_var ?? null)
  const treatment = props.applyCorrection(props.draft.treatment_var ?? null)
  const controls = (props.draft.controls ?? []).map((v) => props.applyCorrection(v) ?? placeholderDash)

  return (
    <div className="panel">
      <div className="panel-body">
        <span className="section-label" style={{ margin: 0 }}>
          {zhCN.variables.heading}
        </span>
        <div className="data-table-wrap" style={{ marginTop: 12 }}>
          <table className="data-table">
            <thead>
              <tr>
                <th>{zhCN.variables.headers.role}</th>
                <th>{zhCN.variables.headers.variable}</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td className="mono">{zhCN.variables.roles.outcome}</td>
                <td>{outcome ?? placeholderDash}</td>
              </tr>
              <tr>
                <td className="mono">{zhCN.variables.roles.treatment}</td>
                <td>{treatment ?? placeholderDash}</td>
              </tr>
              <tr>
                <td className="mono">{zhCN.variables.roles.controls}</td>
                <td>{controls.length > 0 ? controls.join(', ') : placeholderDash}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}

export function WarningsPanel(props: { warnings: DraftPreviewReadyResponse['data_quality_warnings'] }) {
  const placeholderDash = zhCN.common.placeholderDash
  const warnings = props.warnings
  if (warnings === undefined || warnings.length === 0) return null
  return (
    <div className="panel">
      <div className="panel-body">
        <span className="section-label" style={{ margin: 0 }}>
          {zhCN.warnings.heading}
        </span>
        <div className="data-table-wrap" style={{ marginTop: 12, maxHeight: 220 }}>
          <table className="data-table">
            <thead>
              <tr>
                <th>{zhCN.warnings.headers.severity}</th>
                <th>{zhCN.warnings.headers.message}</th>
                <th>{zhCN.warnings.headers.suggestion}</th>
              </tr>
            </thead>
            <tbody>
              {warnings.map((w, idx) => (
                <tr key={idx}>
                  <td className="mono">{w.severity}</td>
                  <td>{w.message}</td>
                  <td>{w.suggestion ?? placeholderDash}</td>
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
          {zhCN.draft.heading}
        </span>
        <pre className="mono pre-wrap" style={{ marginTop: 12 }}>
          {props.draftText}
        </pre>
      </div>
    </div>
  )
}
