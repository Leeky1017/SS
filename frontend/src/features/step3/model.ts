import type { DraftOpenUnknown, DraftPreviewPendingResponse, DraftPreviewReadyResponse, DraftPreviewResponse } from '../../api/types'
import { zhCN } from '../../i18n/zh-CN'

export function isDraftPreviewPending(resp: DraftPreviewResponse): resp is DraftPreviewPendingResponse {
  return (resp as DraftPreviewPendingResponse).status === 'pending'
}

export function isBlockingUnknown(unknown: DraftOpenUnknown): boolean {
  if (unknown.blocking === true) return true
  return unknown.impact === 'high' || unknown.impact === 'critical'
}

export function computeCandidates(draft: DraftPreviewReadyResponse, fallbackCandidates: string[]): string[] | null {
  const fromDraft = draft.column_candidates
  if (fromDraft !== undefined && fromDraft.length > 0) return fromDraft
  const fromTypes = draft.variable_types?.map((c) => c.name)
  if (fromTypes !== undefined && fromTypes.length > 0) return fromTypes
  return fallbackCandidates.length > 0 ? fallbackCandidates : null
}

export function applyCorrection(variableCorrections: Record<string, string>, v: string | null): string | null {
  if (v === null) return null
  return variableCorrections[v] ?? v
}

export function blockingMissing(
  draft: DraftPreviewReadyResponse,
  answers: Record<string, string[]>,
  unknownValues: Record<string, string>,
): string | null {
  const questions = draft.stage1_questions
  if (questions !== undefined && questions.length > 0) {
    for (const q of questions) {
      const selected = answers[q.question_id]
      if (selected === undefined || selected.length === 0) return zhCN.stage1.mustAnswerAllBeforeConfirm
    }
  }

  const unknowns = draft.open_unknowns
  if (unknowns !== undefined && unknowns.length > 0) {
    for (const u of unknowns) {
      if (!isBlockingUnknown(u)) continue
      const v = unknownValues[u.field]
      if (v === undefined || v.trim() === '') return zhCN.unknowns.mustFillBlockingBeforeConfirm
    }
  }
  return null
}
