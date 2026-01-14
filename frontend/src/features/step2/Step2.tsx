import { useMemo, useState } from 'react'
import type { ApiClient } from '../../api/client'
import type { ApiError } from '../../api/errors'
import type { InputsPreviewResponse, InputsUploadResponse } from '../../api/types'
import { ErrorPanel } from '../../components/ErrorPanel'
import { zhCN } from '../../i18n/zh-CN'
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
import { JobPanel, PreviewPanel, Step2Header, UploadResultPanel } from './Step2Panels'
import { InputsUploadPanel } from './Step2UploadPanel'

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
  const [primaryFile, setPrimaryFile] = useState<File | null>(null)
  const [auxiliaryFiles, setAuxiliaryFiles] = useState<File[]>([])

  const redeem = useMemo(() => {
    return () => {
      resetToStep1()
      saveAppState({ view: 'step1' })
      window.location.reload()
    }
  }, [])

  const previewRows = 20
  const previewCols = 10

  async function runPreview(jobId: string): Promise<void> {
    setActionError(null)
    setBusy(true)
    try {
      const previewed = await props.api.previewInputsWithOptions(jobId, { rows: previewRows, columns: previewCols })
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

  async function runSelectSheet(jobId: string, sheetName: string): Promise<void> {
    setActionError(null)
    setBusy(true)
    try {
      const selected = await props.api.selectPrimaryExcelSheet(jobId, sheetName, { rows: previewRows, columns: previewCols })
      if (!selected.ok) {
        setActionError({ error: selected.error, retry: () => void runSelectSheet(jobId, sheetName), retryLabel: '重试选择 Sheet' })
        return
      }
      saveInputsPreviewSnapshot(jobId, selected.value)
      setState((prev) => ({ ...prev, preview: selected.value }))
    } finally {
      setBusy(false)
    }
  }

  async function runUpload(jobId: string, primary: File, auxiliary: File[]): Promise<void> {
    setActionError(null)
    setBusy(true)
    try {
      const files = [primary, ...auxiliary]
      const roles = ['primary_dataset', ...auxiliary.map(() => 'auxiliary_data')]
      const uploaded = await props.api.uploadInputs(jobId, files, { role: roles })
      if (!uploaded.ok) {
        setActionError({
          error: uploaded.error,
          retry: () => void runUpload(jobId, primary, auxiliary),
          retryLabel: '重试上传',
        })
        return
      }
      saveInputsUploadSnapshot(jobId, uploaded.value)
      setState((prev) => ({ ...prev, upload: uploaded.value }))

      const previewed = await props.api.previewInputsWithOptions(jobId, { rows: previewRows, columns: previewCols })
      if (!previewed.ok) {
        setActionError({ error: previewed.error, retry: () => void runPreview(jobId), retryLabel: '重试预览' })
        return
      }

      let effectivePreview = previewed.value
      const sheetNames = effectivePreview.sheet_names ?? []
      const selectedSheet = effectivePreview.selected_sheet ?? null
      if (sheetNames.length > 0 && selectedSheet !== null && selectedSheet.trim() !== '') {
        const persisted = await props.api.selectPrimaryExcelSheet(jobId, selectedSheet, { rows: previewRows, columns: previewCols })
        if (persisted.ok) effectivePreview = persisted.value
      }
      saveInputsPreviewSnapshot(jobId, effectivePreview)
      setState((prev) => ({ ...prev, preview: effectivePreview }))
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
      <InputsUploadPanel
        busy={busy}
        primaryFile={primaryFile}
        auxiliaryFiles={auxiliaryFiles}
        onPickPrimary={(file) => setPrimaryFile(file)}
        onClearPrimary={() => setPrimaryFile(null)}
        onAddAuxiliary={(files) => setAuxiliaryFiles((prev) => [...prev, ...files])}
        onRemoveAuxiliary={(index) => setAuxiliaryFiles((prev) => prev.filter((_, idx) => idx !== index))}
        onClearAuxiliary={() => setAuxiliaryFiles([])}
        onUpload={() => {
          if (primaryFile === null) return
          void runUpload(state.jobId as string, primaryFile, auxiliaryFiles)
        }}
      />
      <UploadResultPanel upload={state.upload} />
      <PreviewPanel
        preview={state.preview}
        busy={busy}
        onSelectSheet={(sheetName) => void runSelectSheet(state.jobId as string, sheetName)}
      />

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
            {zhCN.step2.continueToStep3}
          </button>
        </div>
      </div>
    </div>
  )
}
