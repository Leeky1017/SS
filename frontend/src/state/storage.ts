export type AppView = 'step1' | 'step2'

export type AppState = {
  view: AppView
  jobId: string | null
  taskCode: string
  requirement: string
}

const APP_STATE_KEY = 'ss.frontend.v1.state'
const LAST_JOB_ID_KEY = 'ss.last_job_id'

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
      view: parsed.view === 'step2' ? 'step2' : 'step1',
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

export function resetToStep1(): void {
  const state = loadAppState()
  if (state.jobId !== null) {
    clearAuthToken(state.jobId)
  }
  clearLastJobId()
  localStorage.removeItem(APP_STATE_KEY)
}
