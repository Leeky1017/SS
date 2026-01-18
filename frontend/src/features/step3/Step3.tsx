import { useEffect, useMemo, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import type { ApiClient } from '../../api/client'
import type { ApiError } from '../../api/errors'
import type { DraftPreviewReadyResponse } from '../../api/types'
import { ErrorPanel } from '../../components/ErrorPanel'
import { zhCN } from '../../i18n/zh-CN'
import {
  clearJobAfterConfirm,
  loadConfirmLock,
  loadDraftPreviewSnapshot,
  loadInputsPreviewSnapshot,
  resetToStep1,
  saveConfirmLock,
  saveDraftPreviewSnapshot,
} from '../../state/storage'
import { applyCorrection, blockingMissing, computeCandidates, isDraftPreviewPending } from './model'
import { DraftSkeletonPanel, LockedBanner, PendingPanel, DraftTextPanel, Step3Header, VariablesTable, WarningsPanel } from './panelsBase'
import { DowngradeModal, MappingPanel, OpenUnknownsPanel, Stage1QuestionsPanel } from './panelsConfirm'
import { PlanFreezeMissingRequiredPanel } from './PlanFreezeMissingRequiredPanel'
import { parsePlanFreezeMissingRequiredDetails, VARIABLE_SELECTION_PARAMS } from './planFreezeMissingRequired'
import { Step3MissingJobId } from './Step3MissingJobId'
import { useStep3FormDraft } from './useStep3FormDraft'
import { localValidationError } from './step3Validation'

type Step3Props = { api: ApiClient }

type Step3Error = { error: ApiError; retry: () => void; retryLabel: string }

type DraftState =
  | { kind: 'idle' }
  | { kind: 'loading' }
  | { kind: 'pending'; retryAfterSeconds: number; message: string | null }
  | { kind: 'ready'; draft: DraftPreviewReadyResponse }

export function Step3(props: Step3Props) {
  const navigate = useNavigate()
  const jobId = useParams().jobId ?? null

  const [draftState, setDraftState] = useState<DraftState>(() => {
    if (jobId === null) return { kind: 'idle' }
    const snapshot = loadDraftPreviewSnapshot(jobId)
    if (snapshot === null || isDraftPreviewPending(snapshot)) return { kind: 'idle' }
    return { kind: 'ready', draft: snapshot }
  })
  const [busy, setBusy] = useState(false)
  const [actionError, setActionError] = useState<Step3Error | null>(null)
  const [lock, setLock] = useState(() => (jobId === null ? null : loadConfirmLock(jobId)))
  const [unknownValues, setUnknownValues] = useState<Record<string, string>>({})
  const [patchSupported, setPatchSupported] = useState(true)
  const [patchDisabledReason, setPatchDisabledReason] = useState<string | null>(null)
  const [downgradeModalOpen, setDowngradeModalOpen] = useState(false)

  const locked = lock !== null
  const { variableCorrections, setVariableCorrections, answers, setAnswers, restoredNotice, clear: clearFormDraft } = useStep3FormDraft(jobId, locked, actionError === null || (actionError.error.kind !== 'unauthorized' && actionError.error.kind !== 'forbidden'))

  const redeem = useMemo(() => {
    return () => {
      resetToStep1(jobId)
      navigate('/new')
    }
  }, [jobId, navigate])

  const fallbackCandidates = useMemo(() => {
    if (jobId === null) return []
    const preview = loadInputsPreviewSnapshot(jobId)
    return preview?.columns?.map((c) => c.name) ?? []
  }, [jobId])

  const candidates = useMemo(() => {
    if (draftState.kind !== 'ready') return null
    return computeCandidates(draftState.draft, fallbackCandidates)
  }, [draftState, fallbackCandidates])

  function setCorrection(from: string, to: string | null): void {
    setVariableCorrections((prev) => {
      const next = { ...prev }
      if (to === null) delete next[from]
      else next[from] = to
      return next
    })
  }

  const apply = useMemo(() => {
    return (v: string | null) => applyCorrection(variableCorrections, v)
  }, [variableCorrections])

  const planFreezeMissingDetails = useMemo(() => {
    if (actionError === null) return null
    if (actionError.error.internalCode !== 'PLAN_FREEZE_MISSING_REQUIRED') return null
    return parsePlanFreezeMissingRequiredDetails(actionError.error.details)
  }, [actionError])

  const needsPlanFreezeVariableSelection = useMemo(() => {
    if (planFreezeMissingDetails === null) return false
    return planFreezeMissingDetails.missingParamsDetail.some((item) => VARIABLE_SELECTION_PARAMS.has(item.param))
  }, [planFreezeMissingDetails])

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
        setDraftState({ kind: 'pending', retryAfterSeconds: previewed.value.retry_after_seconds, message: null })
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
      const stage1Questions = draftState.draft.stage1_questions ?? []
      const answersPayload = stage1Questions.length > 0 ? answers : {}
      const result = await props.api.confirmJob(jobId, {
        confirmed: true,
        notes: null,
        variable_corrections: variableCorrections,
        answers: answersPayload,
        default_overrides: draftState.draft.default_overrides ?? {},
        expert_suggestions_feedback: {},
      })
      if (!result.ok) {
        setActionError({ error: result.error, retry: () => void doConfirm(), retryLabel: zhCN.step3.retryConfirm })
        return
      }
      clearJobAfterConfirm(jobId)
      clearFormDraft()
      const confirmedAt = new Date().toISOString()
      saveConfirmLock(jobId, confirmedAt)
      setLock({ confirmedAt })
      navigate(`/jobs/${encodeURIComponent(jobId)}/status`)
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
    setActionError(null)
    setUnknownValues({})
    setPatchSupported(true)
    setPatchDisabledReason(null)
    setDowngradeModalOpen(false)
    setLock(jobId === null ? null : loadConfirmLock(jobId))
    if (jobId === null) {
      setDraftState({ kind: 'idle' })
      return
    }
    void loadDraft()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [jobId])

  useEffect(() => {
    if (jobId === null || draftState.kind !== 'pending') return
    const t = window.setTimeout(() => void loadDraft(), Math.max(1, draftState.retryAfterSeconds) * 1000)
    return () => window.clearTimeout(t)
  }, [draftState, jobId])

  if (jobId === null) {
    return <Step3MissingJobId onRedeem={redeem} />
  }

  return (
    <div className="view-fade">
      <Step3Header onGoToStep2={() => navigate(`/jobs/${encodeURIComponent(jobId)}/upload`)} />
      <ErrorPanel
        error={actionError?.error ?? null}
        onRetry={needsPlanFreezeVariableSelection ? undefined : actionError?.retry}
        retryLabel={needsPlanFreezeVariableSelection ? undefined : actionError?.retryLabel}
        onRedeem={redeem}
      />
      {restoredNotice ? (
        <div className="panel">
          <div className="panel-body">
            <div className="inline-hint">{restoredNotice}</div>
          </div>
        </div>
      ) : null}
      {planFreezeMissingDetails !== null && actionError !== null ? (
        <PlanFreezeMissingRequiredPanel
          details={planFreezeMissingDetails}
          busy={busy}
          locked={locked}
          variableCorrections={variableCorrections}
          fallbackCandidates={candidates}
          onSetCorrection={setCorrection}
          onRetry={actionError.retry}
        />
      ) : null}
      <LockedBanner lock={lock} />

      {draftState.kind === 'pending' ? <PendingPanel message={draftState.message} retryAfterSeconds={draftState.retryAfterSeconds} /> : draftState.kind === 'loading' ? <DraftSkeletonPanel /> : null}

      {draftState.kind === 'ready' ? (
        <>
          <VariablesTable draft={draftState.draft} applyCorrection={apply} />
          <WarningsPanel warnings={draftState.draft.data_quality_warnings} />
          <MappingPanel
            locked={locked}
            draft={draftState.draft}
            candidates={candidates}
            variableCorrections={variableCorrections}
            onSet={setCorrection}
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
