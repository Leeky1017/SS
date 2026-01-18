import type { DraftPreviewResponse, InputsPreviewResponse, InputsUploadResponse } from '../api/types'

export type AppState = {
  taskCode: string
  requirement: string
}

const APP_STATE_KEY = 'ss.frontend.v1.state'

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

const SNAPSHOT_NAMES = [
  'inputs_upload',
  'inputs_preview',
  'inputs_primary_sheet',
  'draft_preview',
  'confirm_lock',
  'step3_form',
] as const

type SnapshotName = (typeof SNAPSHOT_NAMES)[number]

function clearSnapshot(jobId: string, name: SnapshotName): void {
  localStorage.removeItem(snapshotKey(jobId, name))
}

export function loadAppState(): AppState {
  const fallback: AppState = { taskCode: '', requirement: '' }
  const raw = localStorage.getItem(APP_STATE_KEY)
  if (raw === null) return fallback
  const parsed = readJson<Partial<AppState>>(raw)
  if (parsed === null) return fallback
  return {
    taskCode: typeof parsed.taskCode === 'string' ? parsed.taskCode : '',
    requirement: typeof parsed.requirement === 'string' ? parsed.requirement : '',
  }
}

export function saveAppState(next: Partial<AppState>): void {
  const current = loadAppState()
  const merged: AppState = { taskCode: next.taskCode ?? current.taskCode, requirement: next.requirement ?? current.requirement }
  localStorage.setItem(APP_STATE_KEY, JSON.stringify(merged))
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

export function loadInputsPrimarySheetSelection(jobId: string): string | null {
  const parsed = readJson<unknown>(localStorage.getItem(snapshotKey(jobId, 'inputs_primary_sheet')))
  return typeof parsed === 'string' && parsed.trim() !== '' ? parsed : null
}

export function saveInputsPrimarySheetSelection(jobId: string, sheetName: string): void {
  localStorage.setItem(snapshotKey(jobId, 'inputs_primary_sheet'), JSON.stringify(sheetName))
}

export function clearInputsPrimarySheetSelection(jobId: string): void {
  clearSnapshot(jobId, 'inputs_primary_sheet')
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

export type Step3FormState = {
  variableCorrections: Record<string, string>
  answers: Record<string, string[]>
}

function isStringRecord(value: unknown): value is Record<string, string> {
  if (value === null || typeof value !== 'object') return false
  for (const entry of Object.entries(value)) {
    if (typeof entry[0] !== 'string') return false
    if (typeof entry[1] !== 'string') return false
  }
  return true
}

function isAnswersRecord(value: unknown): value is Record<string, string[]> {
  if (value === null || typeof value !== 'object') return false
  for (const entry of Object.entries(value)) {
    if (typeof entry[0] !== 'string') return false
    if (!Array.isArray(entry[1])) return false
    if (!entry[1].every((v) => typeof v === 'string')) return false
  }
  return true
}

export function loadStep3FormState(jobId: string): Step3FormState | null {
  const parsed = readJson<unknown>(localStorage.getItem(snapshotKey(jobId, 'step3_form')))
  if (parsed === null || typeof parsed !== 'object') return null
  if (!('variableCorrections' in parsed) || !('answers' in parsed)) return null

  const variableCorrections = (parsed as { variableCorrections: unknown }).variableCorrections
  const answers = (parsed as { answers: unknown }).answers
  if (!isStringRecord(variableCorrections)) return null
  if (!isAnswersRecord(answers)) return null

  return { variableCorrections, answers }
}

export function saveStep3FormState(jobId: string, snapshot: Step3FormState): void {
  localStorage.setItem(snapshotKey(jobId, 'step3_form'), JSON.stringify(snapshot))
}

export function clearStep3FormState(jobId: string): void {
  clearSnapshot(jobId, 'step3_form')
}

export function clearJobSnapshots(jobId: string): void {
  for (const name of SNAPSHOT_NAMES) clearSnapshot(jobId, name)
}

export function clearJobOnAuthInvalid(jobId: string): void {
  clearAuthToken(jobId)
  clearJobSnapshots(jobId)
}

export function clearJobAfterConfirm(jobId: string): void {
  clearInputsPrimarySheetSelection(jobId)
  clearStep3FormState(jobId)
}

export function resetToStep1(jobId: string | null): void {
  if (jobId !== null) {
    clearAuthToken(jobId)
    clearJobSnapshots(jobId)
  }
  localStorage.removeItem(APP_STATE_KEY)
}
