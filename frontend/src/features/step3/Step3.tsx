import { useEffect, useMemo, useState } from 'react'
import type { ApiClient } from '../../api/client'
import type { ApiError } from '../../api/errors'
import type { DraftPreviewPendingResponse, DraftPreviewReadyResponse } from '../../api/types'
import { ErrorPanel } from '../../components/ErrorPanel'
import { zhCN } from '../../i18n/zh-CN'
import {
  loadAppState,
  loadConfirmLock,
  loadDraftPreviewSnapshot,
  loadInputsPreviewSnapshot,
  resetToStep1,
  saveAppState,
  saveConfirmLock,
  saveDraftPreviewSnapshot,
} from '../../state/storage'
import { applyCorrection, blockingMissing, computeCandidates, isDraftPreviewPending } from './model'
import { LockedBanner, PendingPanel, DraftTextPanel, Step3Header, VariablesTable, WarningsPanel } from './panelsBase'
import { DowngradeModal, MappingPanel, OpenUnknownsPanel, Stage1QuestionsPanel } from './panelsConfirm'

type Step3Props = { api: ApiClient }

type Step3Error = { error: ApiError; retry: () => void; retryLabel: string }

type DraftState =
  | { kind: 'idle' }
  | { kind: 'loading' }
  | { kind: 'pending'; retryAfterSeconds: number; message: string | null }
  | { kind: 'ready'; draft: DraftPreviewReadyResponse }

function pendingMessage(resp: DraftPreviewPendingResponse): string | null {
  if (typeof resp.message === 'string' && resp.message.trim() !== '') return resp.message
  return null
}

function localValidationError(message: string, requestId: string): ApiError {
  return { kind: 'http', status: null, message, requestId, details: null, action: 'retry' }
}

export function Step3(props: Step3Props) {
  const { jobId } = loadAppState()

  const [draftState, setDraftState] = useState<DraftState>(() => {
    if (jobId === null) return { kind: 'idle' }
    const snapshot = loadDraftPreviewSnapshot(jobId)
    if (snapshot === null || isDraftPreviewPending(snapshot)) return { kind: 'idle' }
    return { kind: 'ready', draft: snapshot }
  })
  const [busy, setBusy] = useState(false)
  const [actionError, setActionError] = useState<Step3Error | null>(null)
  const [lock, setLock] = useState(() => (jobId === null ? null : loadConfirmLock(jobId)))
  const [variableCorrections, setVariableCorrections] = useState<Record<string, string>>({})
  const [answers, setAnswers] = useState<Record<string, string[]>>({})
  const [unknownValues, setUnknownValues] = useState<Record<string, string>>({})
  const [patchSupported, setPatchSupported] = useState(true)
  const [patchDisabledReason, setPatchDisabledReason] = useState<string | null>(null)
  const [downgradeModalOpen, setDowngradeModalOpen] = useState(false)

  const locked = lock !== null

  const redeem = useMemo(() => {
    return () => {
      resetToStep1()
      saveAppState({ view: 'step1' })
      window.location.reload()
    }
  }, [])

  const fallbackCandidates = useMemo(() => {
    if (jobId === null) return []
    const preview = loadInputsPreviewSnapshot(jobId)
    return preview?.columns.map((c) => c.name) ?? []
  }, [jobId])

  const candidates = useMemo(() => {
    if (draftState.kind !== 'ready') return null
    return computeCandidates(draftState.draft, fallbackCandidates)
  }, [draftState, fallbackCandidates])

  const apply = useMemo(() => {
    return (v: string | null) => applyCorrection(variableCorrections, v)
  }, [variableCorrections])

  async function loadDraft(): Promise<void> {
    if (jobId === null) return
    setActionError(null)
    setBusy(true)
    setDraftState({ kind: 'loading' })
    try {
      const previewed = await props.api.previewDraft(jobId)
      if (!previewed.ok) {
        setDraftState({ kind: 'idle' })
        setActionError({ error: previewed.error, retry: () => void loadDraft(), retryLabel: zhCN.step3.retryLoadDraft })
        return
      }
      saveDraftPreviewSnapshot(jobId, previewed.value)
      if (isDraftPreviewPending(previewed.value)) {
        setDraftState({ kind: 'pending', retryAfterSeconds: previewed.value.retry_after_seconds, message: pendingMessage(previewed.value) })
        return
      }
      setDraftState({ kind: 'ready', draft: previewed.value })
    } finally {
      setBusy(false)
    }
  }

  async function patchDraft(): Promise<void> {
    if (jobId === null || !patchSupported) return
    setActionError(null)
    setBusy(true)
    try {
      const result = await props.api.patchDraft(jobId, { field_updates: unknownValues })
      if (!result.ok) {
        if (result.error.kind === 'http' && (result.error.status === 404 || result.error.status === 501)) {
          setPatchSupported(false)
          setPatchDisabledReason(zhCN.unknowns.patchNotProvided404501)
          return
        }
        setActionError({ error: result.error, retry: () => void patchDraft(), retryLabel: zhCN.step3.retryPatchDraft })
        return
      }
      await loadDraft()
    } finally {
      setBusy(false)
    }
  }

  async function doConfirm(): Promise<void> {
    if (jobId === null || draftState.kind !== 'ready') return
    setDowngradeModalOpen(false)
    setActionError(null)
    setBusy(true)
    try {
      const answersPayload = draftState.draft.stage1_questions.length > 0 ? answers : {}
      const result = await props.api.confirmJob(jobId, {
        confirmed: true,
        notes: null,
        variable_corrections: variableCorrections,
        answers: answersPayload,
        default_overrides: draftState.draft.default_overrides,
        expert_suggestions_feedback: {},
      })
      if (!result.ok) {
        setActionError({ error: result.error, retry: () => void doConfirm(), retryLabel: zhCN.step3.retryConfirm })
        return
      }
      const confirmedAt = new Date().toISOString()
      saveConfirmLock(jobId, confirmedAt)
      setLock({ confirmedAt })
      saveAppState({ view: 'status' })
      window.location.reload()
    } finally {
      setBusy(false)
    }
  }

  async function confirm(): Promise<void> {
    if (jobId === null || draftState.kind !== 'ready' || locked) return
    const missing = blockingMissing(draftState.draft, answers, unknownValues)
    if (missing !== null) {
      const rid = props.api.lastRequestId ?? 'n/a'
      setActionError({ error: localValidationError(missing, rid), retry: () => void confirm(), retryLabel: zhCN.actions.recheck })
      return
    }
    if (draftState.draft.decision === 'require_confirm_with_downgrade') {
      setDowngradeModalOpen(true)
      return
    }
    await doConfirm()
  }

  useEffect(() => {
    if (jobId === null) return
    void loadDraft()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [jobId])

  useEffect(() => {
    if (jobId === null || draftState.kind !== 'pending') return
    const t = window.setTimeout(() => void loadDraft(), Math.max(1, draftState.retryAfterSeconds) * 1000)
    return () => window.clearTimeout(t)
  }, [draftState, jobId])

  if (jobId === null) {
    return (
      <div className="view-fade">
        <Step3Header />
        <div className="panel">
          <div className="panel-body">
            <div style={{ fontWeight: 600, marginBottom: 6 }}>{zhCN.step3.missingJobIdTitle}</div>
            <div className="inline-hint">{zhCN.step3.missingJobIdHint}</div>
            <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 12 }}>
              <button className="btn btn-primary" type="button" onClick={redeem}>
                {zhCN.step3.backToStep1}
              </button>
            </div>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="view-fade">
      <Step3Header />
      <ErrorPanel error={actionError?.error ?? null} onRetry={actionError?.retry} retryLabel={actionError?.retryLabel} onRedeem={redeem} />
      <LockedBanner lock={lock} />

      {draftState.kind === 'pending' ? (
        <PendingPanel message={draftState.message} retryAfterSeconds={draftState.retryAfterSeconds} />
      ) : null}

      {draftState.kind === 'ready' ? (
        <>
          <VariablesTable draft={draftState.draft} applyCorrection={apply} />
          <WarningsPanel warnings={draftState.draft.data_quality_warnings} />
          <MappingPanel
            locked={locked}
            draft={draftState.draft}
            candidates={candidates}
            variableCorrections={variableCorrections}
            onSet={(from, to) =>
              setVariableCorrections((prev) => {
                const next = { ...prev }
                if (to === null) delete next[from]
                else next[from] = to
                return next
              })
            }
            onClearAll={() => setVariableCorrections({})}
          />
          {draftState.draft.stage1_questions !== undefined ? (
            <Stage1QuestionsPanel
              locked={locked}
              questions={draftState.draft.stage1_questions}
              answers={answers}
              onSetAnswer={(questionId, next) => setAnswers((prev) => ({ ...prev, [questionId]: next }))}
            />
          ) : null}
          {draftState.draft.open_unknowns !== undefined ? (
            <OpenUnknownsPanel
              locked={locked}
              unknowns={draftState.draft.open_unknowns}
              values={unknownValues}
              onChange={(field, value) => setUnknownValues((prev) => ({ ...prev, [field]: value }))}
              patchSupported={patchSupported}
              patchDisabledReason={patchDisabledReason}
              onPatch={() => void patchDraft()}
            />
          ) : null}
          <DraftTextPanel draftText={draftState.draft.draft_text} />
        </>
      ) : null}

      <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, marginTop: 24 }}>
        <button className="btn btn-secondary" type="button" onClick={redeem} disabled={busy}>
          {zhCN.actions.redeemAgain}
        </button>
        <div style={{ display: 'flex', gap: 12 }}>
          <button className="btn btn-secondary" type="button" onClick={() => void loadDraft()} disabled={busy}>
            {zhCN.step3.refreshDraft}
          </button>
          <button className="btn btn-primary" type="button" onClick={() => void confirm()} disabled={busy || locked || draftState.kind !== 'ready'}>
            {zhCN.actions.confirmAndStart}
          </button>
        </div>
      </div>

      <DowngradeModal open={downgradeModalOpen} onCancel={() => setDowngradeModalOpen(false)} onConfirm={() => void doConfirm()} />
    </div>
  )
}
