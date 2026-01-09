import { useEffect, useMemo, useState } from 'react'
import type { ApiClient } from '../../api/client'
import type { ApiError } from '../../api/errors'
import { loadAppState, saveAppState, setAuthToken, setLastJobId } from '../../state/storage'

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

function tplText(id: 'ols' | 'diff'): string {
  if (id === 'diff') {
    return '希望采用 DID（双重差分）检验政策冲击对企业表现的影响，需要控制个体与时间固定效应，并进行并行趋势检验。'
  }
  return '希望进行面板回归（OLS/FE/RE），分析核心解释变量对被解释变量的影响，需要控制个体与时间固定效应，并进行稳健性检验。'
}

function formError(message: string, requestId: string): ApiError {
  return { kind: 'http', status: null, message, requestId, details: null, action: 'retry' }
}

function errorTitle(error: ApiError): string {
  if (error.kind === 'unauthorized' || error.kind === 'forbidden') {
    return '未授权'
  }
  return '请求失败'
}

type Step1SubmitResult = { ok: true; jobId: string; token: string | null } | { ok: false; error: ApiError }

async function submitStep1(api: ApiClient, taskCode: string, requirement: string): Promise<Step1SubmitResult> {
  if (requirement.trim() === '') return { ok: false, error: formError('请填写研究设想与需求', api.lastRequestId ?? 'n/a') }
  if (taskCode.trim() === '' && api.requireTaskCode()) {
    return { ok: false, error: formError('当前环境要求必须填写 Task Code（VITE_REQUIRE_TASK_CODE=1）', api.lastRequestId ?? 'n/a') }
  }

  const trimmedRequirement = requirement.trim()
  const trimmedCode = taskCode.trim()
  if (trimmedCode === '' && api.canFallbackToCreateJob()) {
    const created = await api.createJob({ requirement: trimmedRequirement })
    return created.ok ? { ok: true, jobId: created.value.job_id, token: null } : { ok: false, error: created.error }
  }

  const redeemed = await api.redeemTaskCode({ task_code: trimmedCode, requirement: trimmedRequirement })
  if (redeemed.ok) return { ok: true, jobId: redeemed.value.job_id, token: redeemed.value.token }
  if (redeemed.error.status === 404 && api.canFallbackToCreateJob()) {
    const created = await api.createJob({ requirement: trimmedRequirement })
    return created.ok ? { ok: true, jobId: created.value.job_id, token: null } : { ok: false, error: created.error }
  }
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
  const fields = useStep1Fields()
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<ApiError | null>(null)

  const hint = useMemo(() => {
    if (!import.meta.env.DEV) return null
    if (api.isDevMockEnabled()) return 'DEV: Mock redeem 已启用（VITE_API_MOCK=0 可关闭）'
    if (api.canFallbackToCreateJob()) return 'DEV: 可回退到 POST /v1/jobs（VITE_REQUIRE_TASK_CODE=1 可禁用）'
    return null
  }, [api])

  async function submit(): Promise<void> {
    setError(null)
    setBusy(true)
    try {
      const result = await submitStep1(api, fields.taskCode, fields.requirement)
      if (!result.ok) return setError(result.error)
      setLastJobId(result.jobId)
      if (result.token !== null) setAuthToken(result.jobId, result.token)
      saveAppState({ view: 'step2', jobId: result.jobId })
      return window.location.reload()
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

function ErrorPanel(props: { error: ApiError | null }) {
  if (props.error === null) return null
  return (
    <div className="panel error-panel">
      <div className="panel-body">
        <div style={{ fontWeight: 600, marginBottom: 6 }}>{errorTitle(props.error)}</div>
        <div style={{ color: 'var(--text-dim)' }}>{props.error.message}</div>
        <div className="mono" style={{ marginTop: 10, color: 'var(--text-muted)' }}>
          request_id: {props.error.requestId}
        </div>
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
        placeholder="输入 Task Code"
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
        <div style={{ display: 'flex', gap: 8 }}>
          <button className="btn btn-secondary" type="button" style={{ height: 28 }} onClick={() => props.onChange(tplText('ols'))}>
            面板回归
          </button>
          <button className="btn btn-secondary" type="button" style={{ height: 28 }} onClick={() => props.onChange(tplText('diff'))}>
            DID 模型
          </button>
        </div>
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
      <RequirementField value={model.requirement} busy={model.busy} onChange={model.setRequirement} onSubmit={onSubmit} />
      <Step1Actions busy={model.busy} onSubmit={onSubmit} />
    </div>
  )
}
