import { useState } from 'react'
import type { ApiError } from '../api/errors'
import { zhCN } from '../i18n/zh-CN'

function errorTitle(error: ApiError): string {
  if (error.kind === 'unauthorized' || error.kind === 'forbidden') return zhCN.errors.unauthorizedTitle
  return zhCN.errors.requestFailedTitle
}

function readNonEmptyDetailString(details: unknown, field: string): string | null {
  if (details === null || details === undefined) return null
  if (typeof details !== 'object') return null
  const raw = (details as Record<string, unknown>)[field]
  if (typeof raw !== 'string') return null
  const trimmed = raw.trim()
  return trimmed === '' ? null : trimmed
}

function formatDetails(details: unknown): string {
  try {
    return JSON.stringify(details, null, 2)
  } catch {
    return String(details)
  }
}

type ErrorPanelProps = {
  error: ApiError | null
  onRetry?: () => void
  retryLabel?: string
  onRedeem?: () => void
}

export function ErrorPanel(props: ErrorPanelProps) {
  const [copied, setCopied] = useState(false)
  const error = props.error
  if (error === null) return null

  const showRetry = error.action === 'retry' && props.onRetry !== undefined
  const showRedeem = error.action === 'redeem' && props.onRedeem !== undefined
  const hint = readNonEmptyDetailString(error.details, 'action') ?? readNonEmptyDetailString(error.details, 'message')
  const showDetails = error.details !== null && error.details !== undefined
  const requestId = error.requestId

  async function copyRequestId(): Promise<void> {
    try {
      await navigator.clipboard.writeText(requestId)
      setCopied(true)
      window.setTimeout(() => setCopied(false), 1200)
    } catch {
      setCopied(false)
    }
  }

  return (
    <div className="panel error-panel">
      <div className="panel-body">
        <div style={{ fontWeight: 600, marginBottom: 6 }}>{errorTitle(error)}</div>
        <div style={{ color: 'var(--text-dim)' }}>{error.message}</div>
        {hint !== null ? (
          <div className="inline-hint" style={{ marginTop: 10 }}>
            {hint}
          </div>
        ) : null}
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, marginTop: 10, alignItems: 'baseline' }}>
          <div className="mono" style={{ color: 'var(--text-muted)' }}>
            {zhCN.errors.requestIdLabel}: {requestId}
          </div>
          <button className="btn btn-secondary" type="button" onClick={() => void copyRequestId()}>
            {copied ? zhCN.actions.copied : zhCN.actions.copy}
          </button>
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
        {showDetails ? (
          <details style={{ marginTop: 12 }}>
            <summary className="inline-hint">{zhCN.errors.technicalDetailsLabel}</summary>
            <pre className="mono" style={{ marginTop: 8, whiteSpace: 'pre-wrap', color: 'var(--text-muted)' }}>
              {formatDetails(error.details)}
            </pre>
          </details>
        ) : null}
      </div>
    </div>
  )
}
