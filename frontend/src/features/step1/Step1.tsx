import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import type { ApiClient } from '../../api/client'
import type { ApiError } from '../../api/errors'
import { ErrorPanel } from '../../components/ErrorPanel'
import { loadAppState, saveAppState, setAuthToken } from '../../state/storage'
import { toUserErrorMessage } from '../../utils/errorCodes'
import { AnalysisGuidePanel } from './AnalysisGuidePanel'

type Step1Props = { api: ApiClient }

type Step1Model = {
  taskCode: string
  requirement: string
  busy: boolean
  error: ApiError | null
  hint: string | null
  setTaskCode: (next: string) => void
  setRequirement: (next: string) => void
  submit: () => Promise<void>
}

function formError(internalCode: string, requestId: string): ApiError {
  const kind = 'http'
  const status = 400
  return {
    kind,
    status,
    message: toUserErrorMessage({ internalCode, kind, status }),
    requestId,
    details: null,
    internalCode,
    action: 'retry',
  }
}

type Step1SubmitResult = { ok: true; jobId: string; token: string | null } | { ok: false; error: ApiError }

async function submitStep1(api: ApiClient, taskCode: string, requirement: string): Promise<Step1SubmitResult> {
  if (requirement.trim() === '') return { ok: false, error: formError('MISSING_REQUIRED_FIELD', api.lastRequestId ?? 'n/a') }
  if (taskCode.trim() === '' && api.requireTaskCode()) {
    return { ok: false, error: formError('MISSING_REQUIRED_FIELD', api.lastRequestId ?? 'n/a') }
  }

  const trimmedRequirement = requirement.trim()
  const trimmedCode = taskCode.trim()
  const effectiveCode = trimmedCode !== '' ? trimmedCode : `tc_dev_${Date.now().toString(16)}`

  const redeemed = await api.redeemTaskCode({ task_code: effectiveCode, requirement: trimmedRequirement })
  if (redeemed.ok) return { ok: true, jobId: redeemed.value.job_id, token: redeemed.value.token }
  return { ok: false, error: redeemed.error }
}

function useStep1Fields(): Pick<Step1Model, 'taskCode' | 'requirement' | 'setTaskCode' | 'setRequirement'> {
  const [taskCode, setTaskCode] = useState(() => loadAppState().taskCode)
  const [requirement, setRequirement] = useState(() => loadAppState().requirement)

  useEffect(() => {
    saveAppState({ taskCode, requirement })
  }, [taskCode, requirement])

  return { taskCode, requirement, setTaskCode, setRequirement }
}

function useStep1Model(api: ApiClient): Step1Model {
  const navigate = useNavigate()
  const fields = useStep1Fields()
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<ApiError | null>(null)

  const hint = useMemo(() => {
    if (!import.meta.env.DEV) return null
    if (api.isDevMockEnabled()) return '开发模式：已启用模拟通道'
    return null
  }, [api])

  async function submit(): Promise<void> {
    setError(null)
    setBusy(true)
    try {
      const result = await submitStep1(api, fields.taskCode, fields.requirement)
      if (!result.ok) return setError(result.error)
      if (result.token !== null) setAuthToken(result.jobId, result.token)
      navigate(`/jobs/${encodeURIComponent(result.jobId)}/upload`)
    } finally {
      setBusy(false)
    }
  }

  return { ...fields, busy, error, hint, submit }
}

function Step1Header() {
  return (
    <>
      <div className="stepper">
        <div className="step-tick active" />
        <div className="step-tick" />
        <div className="step-tick" />
      </div>
      <h1>开启智能化分析</h1>
      <p className="lead">Stata 18 MP 分析引擎将自动为您构建全量实证模型并生成可执行脚本。完成以下必要信息即可开始。</p>
    </>
  )
}

function DevHintPanel(props: { hint: string | null }) {
  if (props.hint === null) return null
  return (
    <div className="panel">
      <div className="panel-body">
        <div className="inline-hint">{props.hint}</div>
      </div>
    </div>
  )
}

function TaskCodeField(props: { value: string; busy: boolean; onChange: (v: string) => void }) {
  return (
    <div className="control-group">
      <span className="section-label required">任务验证码</span>
      <input
        type="text"
        placeholder="输入任务验证码"
        className="mono"
        value={props.value}
        onChange={(e) => props.onChange(e.target.value)}
        disabled={props.busy}
      />
    </div>
  )
}

function RequirementField(props: { value: string; busy: boolean; onChange: (v: string) => void; onSubmit: () => void }) {
  return (
    <div className="control-group">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
        <span className="section-label required" style={{ margin: 0 }}>
          研究设想与需求
        </span>
      </div>
      <textarea
        placeholder="例如：分析 ESG 表现对企业价值的影响，需要控制个体与时间效应..."
        value={props.value}
        onChange={(e) => props.onChange(e.target.value)}
        onKeyDown={(e) => {
          if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') props.onSubmit()
        }}
        disabled={props.busy}
      />
    </div>
  )
}

function Step1Actions(props: { busy: boolean; onSubmit: () => void }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 12, marginTop: 48 }}>
      <button className="btn btn-primary" type="button" onClick={props.onSubmit} disabled={props.busy}>
        {props.busy ? (
          '提交中…'
        ) : (
          <>
            继续 <span className="shortcut">⌘ ↵</span>
          </>
        )}
      </button>
    </div>
  )
}

export function Step1(props: Step1Props) {
  const model = useStep1Model(props.api)
  const onSubmit = () => void model.submit()

  return (
    <div className="view-fade">
      <Step1Header />
      <DevHintPanel hint={model.hint} />
      <ErrorPanel error={model.error} />
      <TaskCodeField value={model.taskCode} busy={model.busy} onChange={model.setTaskCode} />
      <AnalysisGuidePanel busy={model.busy} onApplyTemplate={model.setRequirement} />
      <RequirementField value={model.requirement} busy={model.busy} onChange={model.setRequirement} onSubmit={onSubmit} />
      <Step1Actions busy={model.busy} onSubmit={onSubmit} />
    </div>
  )
}
