import { useMemo, useState } from 'react'
import type { ApiClient } from '../../api/client'
import type { ApiError } from '../../api/errors'
import type { InputsPreviewResponse, InputsUploadResponse } from '../../api/types'
import { ErrorPanel } from '../../components/ErrorPanel'
import {
  getAuthToken,
  loadAppState,
  loadInputsPreviewSnapshot,
  loadInputsUploadSnapshot,
  resetToStep1,
  saveAppState,
  saveInputsPreviewSnapshot,
  saveInputsUploadSnapshot,
} from '../../state/storage'
import { DropZone, JobPanel, PreviewPanel, Step2Header, UploadResultPanel } from './Step2Panels'

type Step2Props = { api: ApiClient }

type Step2Error = { error: ApiError; retry: () => void; retryLabel: string }

type Step2State = {
  jobId: string | null
  tokenPresent: boolean
  upload: InputsUploadResponse | null
  preview: InputsPreviewResponse | null
}

function loadStep2State(): Step2State {
  const app = loadAppState()
  const jobId = app.jobId
  const tokenPresent = jobId !== null && getAuthToken(jobId) !== null
  return {
    jobId,
    tokenPresent,
    upload: jobId === null ? null : loadInputsUploadSnapshot(jobId),
    preview: jobId === null ? null : loadInputsPreviewSnapshot(jobId),
  }
}

export function Step2(props: Step2Props) {
  const [state, setState] = useState<Step2State>(() => loadStep2State())
  const [busy, setBusy] = useState(false)
  const [actionError, setActionError] = useState<Step2Error | null>(null)

  const redeem = useMemo(() => {
    return () => {
      resetToStep1()
      saveAppState({ view: 'step1' })
      window.location.reload()
    }
  }, [])

  async function runPreview(jobId: string): Promise<void> {
    setActionError(null)
    setBusy(true)
    try {
      const previewed = await props.api.previewInputs(jobId)
      if (!previewed.ok) {
        setActionError({ error: previewed.error, retry: () => void runPreview(jobId), retryLabel: '重试预览' })
        return
      }
      saveInputsPreviewSnapshot(jobId, previewed.value)
      setState((prev) => ({ ...prev, preview: previewed.value }))
    } finally {
      setBusy(false)
    }
  }

  async function runUpload(jobId: string, files: File[]): Promise<void> {
    setActionError(null)
    setBusy(true)
    try {
      const uploaded = await props.api.uploadInputs(jobId, files)
      if (!uploaded.ok) {
        setActionError({ error: uploaded.error, retry: () => void runUpload(jobId, files), retryLabel: '重试上传' })
        return
      }
      saveInputsUploadSnapshot(jobId, uploaded.value)
      setState((prev) => ({ ...prev, upload: uploaded.value }))
      await runPreview(jobId)
    } finally {
      setBusy(false)
    }
  }

  if (state.jobId === null) {
    return (
      <div className="view-fade">
        <Step2Header />
        <div className="panel">
          <div className="panel-body">
            <div style={{ fontWeight: 600, marginBottom: 6 }}>缺少 job_id</div>
            <div className="inline-hint">请先完成 Step 1 兑换（或 dev fallback create job）。</div>
            <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 12 }}>
              <button className="btn btn-primary" type="button" onClick={redeem}>
                返回 Step 1
              </button>
            </div>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="view-fade">
      <Step2Header />
      <ErrorPanel
        error={actionError?.error ?? null}
        onRetry={actionError?.retry}
        retryLabel={actionError?.retryLabel}
        onRedeem={redeem}
      />

      <JobPanel jobId={state.jobId} tokenPresent={state.tokenPresent} />
      <DropZone busy={busy} onPick={(files) => void runUpload(state.jobId as string, files)} />
      <UploadResultPanel upload={state.upload} />
      <PreviewPanel preview={state.preview} />

      <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, marginTop: 24 }}>
        <button className="btn btn-secondary" type="button" onClick={redeem} disabled={busy}>
          重新兑换
        </button>
        <div style={{ display: 'flex', gap: 12 }}>
          <button className="btn btn-secondary" type="button" disabled={busy} onClick={() => void runPreview(state.jobId as string)}>
            刷新预览
          </button>
          <button
            className="btn btn-primary"
            type="button"
            disabled={busy || state.upload === null}
            onClick={() => {
              saveAppState({ view: 'step3' })
              window.location.reload()
            }}
          >
            继续：蓝图预检
          </button>
        </div>
      </div>
    </div>
  )
}

