import { useEffect, useMemo, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import type { ApiClient } from '../../api/client'
import type { ApiError } from '../../api/errors'
import type { InputsPreviewResponse, InputsUploadResponse } from '../../api/types'
import { ErrorPanel } from '../../components/ErrorPanel'
import { zhCN } from '../../i18n/zh-CN'
import {
  clearInputsPrimarySheetSelection,
  loadInputsPreviewSnapshot,
  loadInputsPrimarySheetSelection,
  loadInputsUploadSnapshot,
  resetToStep1,
  saveInputsPreviewSnapshot,
  saveInputsPrimarySheetSelection,
  saveInputsUploadSnapshot,
} from '../../state/storage'
import { PreviewPanel, Step2Header } from './Step2Panels'
import { InputsUploadPanel } from './Step2UploadPanel'

type Step2Props = { api: ApiClient }

type Step2Error = { error: ApiError; retry: () => void; retryLabel: string }

type Step2State = {
  upload: InputsUploadResponse | null
  preview: InputsPreviewResponse | null
}

function shouldFallbackFromSheetSelection(error: ApiError): boolean {
  if (error.kind !== 'http') return false
  return error.status === 400 || error.status === 404
}

function loadStep2State(jobId: string): Step2State {
  return {
    upload: loadInputsUploadSnapshot(jobId),
    preview: loadInputsPreviewSnapshot(jobId),
  }
}

export function Step2(props: Step2Props) {
  const navigate = useNavigate()
  const jobId = useParams().jobId ?? null
  const [state, setState] = useState<Step2State>(() => (jobId === null ? { upload: null, preview: null } : loadStep2State(jobId)))
  const [busy, setBusy] = useState(false)
  const [actionError, setActionError] = useState<Step2Error | null>(null)
  const [rememberedSheet, setRememberedSheet] = useState<string | null>(() =>
    jobId === null ? null : loadInputsPrimarySheetSelection(jobId),
  )
  const [primaryFile, setPrimaryFile] = useState<File | null>(null)
  const [auxiliaryFiles, setAuxiliaryFiles] = useState<File[]>([])

  useEffect(() => {
    setActionError(null)
    setPrimaryFile(null)
    setAuxiliaryFiles([])
    setRememberedSheet(jobId === null ? null : loadInputsPrimarySheetSelection(jobId))
    if (jobId === null) return
    setState(loadStep2State(jobId))
  }, [jobId])

  const redeem = useMemo(() => {
    return () => {
      resetToStep1(jobId)
      navigate('/new')
    }
  }, [jobId, navigate])

  const previewRows = 20
  const previewCols = 10

  async function runPreview(jobId: string): Promise<void> {
    setActionError(null)
    setBusy(true)
    try {
      if (rememberedSheet !== null) {
        const selected = await props.api.selectPrimaryExcelSheet(jobId, rememberedSheet, { rows: previewRows, columns: previewCols })
        if (selected.ok) {
          saveInputsPreviewSnapshot(jobId, selected.value)
          setState((prev) => ({ ...prev, preview: selected.value }))
          return
        }
        if (shouldFallbackFromSheetSelection(selected.error)) {
          clearInputsPrimarySheetSelection(jobId)
          setRememberedSheet(null)
        }
        else {
          setActionError({ error: selected.error, retry: () => void runPreview(jobId), retryLabel: '重试预览' })
          return
        }
      }

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
      saveInputsPrimarySheetSelection(jobId, sheetName)
      setRememberedSheet(sheetName)
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

      if (rememberedSheet !== null) {
        const selected = await props.api.selectPrimaryExcelSheet(jobId, rememberedSheet, { rows: previewRows, columns: previewCols })
        if (selected.ok) {
          saveInputsPreviewSnapshot(jobId, selected.value)
          setState((prev) => ({ ...prev, preview: selected.value }))
          return
        }
        if (shouldFallbackFromSheetSelection(selected.error)) {
          clearInputsPrimarySheetSelection(jobId)
          setRememberedSheet(null)
        }
        else {
          setActionError({ error: selected.error, retry: () => void runPreview(jobId), retryLabel: '重试预览' })
          return
        }
      }

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

  if (jobId === null) {
    return (
      <div className="view-fade">
        <Step2Header />
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
          void runUpload(jobId, primaryFile, auxiliaryFiles)
        }}
      />
      <PreviewPanel
        preview={state.preview}
        busy={busy}
        rememberedSheet={rememberedSheet}
        onSelectSheet={(sheetName) => void runSelectSheet(jobId, sheetName)}
      />

      <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, marginTop: 24 }}>
        <button className="btn btn-secondary" type="button" onClick={redeem} disabled={busy}>
          重新兑换
        </button>
        <div style={{ display: 'flex', gap: 12 }}>
          <button className="btn btn-secondary" type="button" disabled={busy} onClick={() => void runPreview(jobId)}>
            刷新预览
          </button>
          <button
            className="btn btn-primary"
            type="button"
            disabled={busy || state.upload === null}
            onClick={() => {
              navigate(`/jobs/${encodeURIComponent(jobId)}/preview`)
            }}
          >
            {zhCN.step2.continueToStep3}
          </button>
        </div>
      </div>
    </div>
  )
}
