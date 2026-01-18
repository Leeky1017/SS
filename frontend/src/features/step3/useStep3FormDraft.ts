import { useEffect, useState } from 'react'
import { clearStep3FormState, loadStep3FormState, saveStep3FormState, type Step3FormState } from '../../state/storage'

type DraftModel = {
  variableCorrections: Record<string, string>
  setVariableCorrections: React.Dispatch<React.SetStateAction<Record<string, string>>>
  answers: Record<string, string[]>
  setAnswers: React.Dispatch<React.SetStateAction<Record<string, string[]>>>
  restoredNotice: string | null
  clear: () => void
}

function hasDraftData(draft: Step3FormState): boolean {
  return Object.keys(draft.variableCorrections).length > 0 || Object.keys(draft.answers).length > 0
}

export function useStep3FormDraft(jobId: string | null, locked: boolean, persistEnabled = true): DraftModel {
  const [variableCorrections, setVariableCorrections] = useState<Record<string, string>>({})
  const [answers, setAnswers] = useState<Record<string, string[]>>({})
  const [restoredNotice, setRestoredNotice] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false
    const loaded = jobId === null ? null : loadStep3FormState(jobId)
    const nextVariableCorrections = loaded?.variableCorrections ?? {}
    const nextAnswers = loaded?.answers ?? {}
    const nextNotice = loaded && hasDraftData(loaded) ? '已从本地草稿恢复已填写内容' : null

    queueMicrotask(() => {
      if (cancelled) return
      setVariableCorrections(nextVariableCorrections)
      setAnswers(nextAnswers)
      setRestoredNotice(nextNotice)
    })

    return () => {
      cancelled = true
    }
  }, [jobId])

  useEffect(() => {
    if (restoredNotice === null) return
    const t = window.setTimeout(() => setRestoredNotice(null), 4500)
    return () => window.clearTimeout(t)
  }, [restoredNotice])

  useEffect(() => {
    if (jobId === null || locked || !persistEnabled) return
    const snapshot: Step3FormState = { variableCorrections, answers }
    const t = window.setTimeout(() => saveStep3FormState(jobId, snapshot), 250)
    return () => window.clearTimeout(t)
  }, [answers, jobId, locked, persistEnabled, variableCorrections])

  return {
    variableCorrections,
    setVariableCorrections,
    answers,
    setAnswers,
    restoredNotice,
    clear: () => {
      if (jobId !== null) clearStep3FormState(jobId)
      setVariableCorrections({})
      setAnswers({})
      setRestoredNotice(null)
    },
  }
}
