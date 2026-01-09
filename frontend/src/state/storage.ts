import type { DraftPreviewResponse, InputsPreviewResponse, InputsUploadResponse } from '../api/types'

export type AppView = 'step1' | 'step2' | 'step3' | 'status'

export type AppState = {
  view: AppView
  jobId: string | null
  taskCode: string
  requirement: string
}

const APP_STATE_KEY = 'ss.frontend.v1.state'
const LAST_JOB_ID_KEY = 'ss.last_job_id'

function normalizeView(view: unknown): AppView {
  if (view === 'step2' || view === 'step3' || view === 'status') return view
  return 'step1'
}

function readJson<T>(raw: string | null): T | null {
  if (raw === null) return null
  try {
    return JSON.parse(raw) as T
  } catch {
    return null
  }
}

function snapshotKey(jobId: string, name: string): string {
  return `ss.frontend.v1.snapshot.${jobId}.${name}`
}

export function loadAppState(): AppState {
  const fallback: AppState = { view: 'step1', jobId: null, taskCode: '', requirement: '' }
  const raw = localStorage.getItem(APP_STATE_KEY)
  if (raw === null) {
    const lastJobId = localStorage.getItem(LAST_JOB_ID_KEY)
    return { ...fallback, jobId: lastJobId, view: lastJobId !== null ? 'step2' : 'step1' }
  }
  try {
    const parsed = JSON.parse(raw) as Partial<AppState>
    return {
      view: normalizeView(parsed.view),
      jobId: typeof parsed.jobId === 'string' ? parsed.jobId : localStorage.getItem(LAST_JOB_ID_KEY),
      taskCode: typeof parsed.taskCode === 'string' ? parsed.taskCode : '',
      requirement: typeof parsed.requirement === 'string' ? parsed.requirement : '',
    }
  } catch {
    const lastJobId = localStorage.getItem(LAST_JOB_ID_KEY)
    return { ...fallback, jobId: lastJobId, view: lastJobId !== null ? 'step2' : 'step1' }
  }
}

export function saveAppState(next: Partial<AppState>): void {
  const current = loadAppState()
  const merged: AppState = {
    view: next.view ?? current.view,
    jobId: next.jobId ?? current.jobId,
    taskCode: next.taskCode ?? current.taskCode,
    requirement: next.requirement ?? current.requirement,
  }
  localStorage.setItem(APP_STATE_KEY, JSON.stringify(merged))
}

export function setLastJobId(jobId: string): void {
  localStorage.setItem(LAST_JOB_ID_KEY, jobId)
}

export function getLastJobId(): string | null {
  return localStorage.getItem(LAST_JOB_ID_KEY)
}

export function clearLastJobId(): void {
  localStorage.removeItem(LAST_JOB_ID_KEY)
}

export function getAuthToken(jobId: string): string | null {
  return localStorage.getItem(`ss.auth.v1.${jobId}`)
}

export function setAuthToken(jobId: string, token: string): void {
  localStorage.setItem(`ss.auth.v1.${jobId}`, token)
}

export function clearAuthToken(jobId: string): void {
  localStorage.removeItem(`ss.auth.v1.${jobId}`)
}

export function loadInputsUploadSnapshot(jobId: string): InputsUploadResponse | null {
  return readJson<InputsUploadResponse>(localStorage.getItem(snapshotKey(jobId, 'inputs_upload')))
}

export function saveInputsUploadSnapshot(jobId: string, snapshot: InputsUploadResponse): void {
  localStorage.setItem(snapshotKey(jobId, 'inputs_upload'), JSON.stringify(snapshot))
}

export function loadInputsPreviewSnapshot(jobId: string): InputsPreviewResponse | null {
  return readJson<InputsPreviewResponse>(localStorage.getItem(snapshotKey(jobId, 'inputs_preview')))
}

export function saveInputsPreviewSnapshot(jobId: string, snapshot: InputsPreviewResponse): void {
  localStorage.setItem(snapshotKey(jobId, 'inputs_preview'), JSON.stringify(snapshot))
}

export function loadDraftPreviewSnapshot(jobId: string): DraftPreviewResponse | null {
  return readJson<DraftPreviewResponse>(localStorage.getItem(snapshotKey(jobId, 'draft_preview')))
}

export function saveDraftPreviewSnapshot(jobId: string, snapshot: DraftPreviewResponse): void {
  localStorage.setItem(snapshotKey(jobId, 'draft_preview'), JSON.stringify(snapshot))
}

export type ConfirmLockState = { confirmedAt: string }

export function loadConfirmLock(jobId: string): ConfirmLockState | null {
  return readJson<ConfirmLockState>(localStorage.getItem(snapshotKey(jobId, 'confirm_lock')))
}

export function saveConfirmLock(jobId: string, confirmedAt: string): void {
  localStorage.setItem(snapshotKey(jobId, 'confirm_lock'), JSON.stringify({ confirmedAt }))
}

export function resetToStep1(): void {
  const state = loadAppState()
  if (state.jobId !== null) {
    clearAuthToken(state.jobId)
  }
  clearLastJobId()
  localStorage.removeItem(APP_STATE_KEY)
}
