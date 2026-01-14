import type { ApiError } from '../api/errors'
import { zhCN } from '../i18n/zh-CN'

function errorTitle(error: ApiError): string {
  if (error.kind === 'unauthorized' || error.kind === 'forbidden') return zhCN.errors.unauthorizedTitle
  return zhCN.errors.requestFailedTitle
}

type ErrorPanelProps = {
  error: ApiError | null
  onRetry?: () => void
  retryLabel?: string
  onRedeem?: () => void
}

export function ErrorPanel(props: ErrorPanelProps) {
  if (props.error === null) return null

  const showRetry = props.error.action === 'retry' && props.onRetry !== undefined
  const showRedeem = props.error.action === 'redeem' && props.onRedeem !== undefined

  return (
    <div className="panel error-panel">
      <div className="panel-body">
        <div style={{ fontWeight: 600, marginBottom: 6 }}>{errorTitle(props.error)}</div>
        <div style={{ color: 'var(--text-dim)' }}>{props.error.message}</div>
        <div className="mono" style={{ marginTop: 10, color: 'var(--text-muted)' }}>
          {zhCN.errors.requestIdLabel}: {props.error.requestId}
        </div>
        {showRetry || showRedeem ? (
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, marginTop: 12 }}>
            {showRedeem ? (
              <button className="btn btn-secondary" type="button" onClick={props.onRedeem}>
                {zhCN.actions.redeemAgain}
              </button>
            ) : null}
            {showRetry ? (
              <button className="btn btn-primary" type="button" onClick={props.onRetry}>
                {props.retryLabel ?? zhCN.actions.retry}
              </button>
            ) : null}
          </div>
        ) : null}
      </div>
    </div>
  )
}
