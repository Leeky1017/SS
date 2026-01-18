import { zhCN } from '../../i18n/zh-CN'
import type { MissingParamDetail, PlanFreezeMissingRequiredDetails } from './planFreezeMissingRequired'
import { VARIABLE_SELECTION_PARAMS } from './planFreezeMissingRequired'

function labelForParam(param: string): string {
  if (param === '__ID_VAR__') return zhCN.errors.planFreezeParamLabels.idVar
  if (param === '__TIME_VAR__') return zhCN.errors.planFreezeParamLabels.timeVar
  if (param === '__PANELVAR__') return zhCN.errors.planFreezeParamLabels.panelVar
  if (param === '__CLUSTER_VAR__') return zhCN.errors.planFreezeParamLabels.clusterVar
  return param
}

function missingVariableSelection(details: PlanFreezeMissingRequiredDetails): MissingParamDetail[] {
  return details.missingParamsDetail.filter((item) => VARIABLE_SELECTION_PARAMS.has(item.param))
}

export function PlanFreezeMissingRequiredPanel(props: {
  details: PlanFreezeMissingRequiredDetails
  busy: boolean
  locked: boolean
  variableCorrections: Record<string, string>
  fallbackCandidates: string[] | null
  onSetCorrection: (from: string, to: string | null) => void
  onRetry: () => void
}) {
  const items = missingVariableSelection(props.details)
  if (items.length === 0) return null

  const requiredParams = new Set(props.details.missingParams.filter((p) => VARIABLE_SELECTION_PARAMS.has(p)))
  const canRetry = [...requiredParams].every((p) => {
    const v = props.variableCorrections[p]
    return v !== undefined && v.trim() !== ''
  })

  return (
    <div className="panel">
      <div className="panel-body">
        <div style={{ fontWeight: 600, marginBottom: 6 }}>{zhCN.errors.planFreezeMissingTitle}</div>
        <div className="inline-hint">{props.details.action ?? zhCN.errors.planFreezeMissingHint}</div>

        <div style={{ display: 'grid', gap: 12, marginTop: 12 }}>
          {items.map((item) => {
            const selected = props.variableCorrections[item.param] ?? ''
            const candidates = item.candidates.length > 0 ? item.candidates : (props.fallbackCandidates ?? [])
            const disabled = props.locked || candidates.length === 0
            return (
              <div key={item.param}>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
                  <div style={{ fontWeight: 600 }}>{labelForParam(item.param)}</div>
                  <div className="inline-hint mono">{item.param}</div>
                </div>
                {item.description.trim() !== '' ? (
                  <div className="inline-hint" style={{ marginTop: 4 }}>
                    {item.description}
                  </div>
                ) : null}
                {candidates.length === 0 ? (
                  <div className="inline-hint" style={{ marginTop: 6 }}>
                    {zhCN.errors.planFreezeMissingCandidatesHint}
                  </div>
                ) : null}
                <div style={{ marginTop: 6 }}>
                  <select
                    value={selected}
                    disabled={disabled}
                    onChange={(e) => props.onSetCorrection(item.param, e.target.value === '' ? null : e.target.value)}
                  >
                    <option value="">{zhCN.common.selectPlaceholder}</option>
                    {candidates.map((c) => (
                      <option key={c} value={c}>
                        {c}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            )
          })}
        </div>

        <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 14 }}>
          <button className="btn btn-primary" type="button" disabled={props.busy || props.locked || !canRetry} onClick={props.onRetry}>
            {zhCN.errors.planFreezeApplyAndRetry}
          </button>
        </div>
      </div>
    </div>
  )
}
