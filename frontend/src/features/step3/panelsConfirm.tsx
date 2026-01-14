import type { DraftOpenUnknown, DraftPreviewReadyResponse, DraftStage1Question } from '../../api/types'
import { controlRoleLabel, zhCN } from '../../i18n/zh-CN'
import { isBlockingUnknown } from './model'

function MappingRow(props: {
  label: string
  value: string | null
  candidates: string[]
  locked: boolean
  corrected: string | null
  onSet: (from: string, to: string | null) => void
}) {
  const placeholderDash = zhCN.common.placeholderDash
  if (props.value === null) return (
    <tr>
      <td className="mono">{props.label}</td>
      <td className="mono">{placeholderDash}</td>
      <td>{placeholderDash}</td>
    </tr>
  )

  return (
    <tr>
      <td className="mono">{props.label}</td>
      <td className="mono">{props.value}</td>
      <td>
        <select
          value={props.corrected ?? ''}
          disabled={props.locked}
          onChange={(e) => props.onSet(props.value as string, e.target.value === '' ? null : e.target.value)}
        >
          <option value="">{zhCN.mapping.optionNoCorrection}</option>
          {props.candidates.map((c) => (
            <option key={c} value={c}>
              {c}
            </option>
          ))}
        </select>
      </td>
    </tr>
  )
}

export function MappingPanel(props: {
  locked: boolean
  draft: DraftPreviewReadyResponse
  candidates: string[] | null
  variableCorrections: Record<string, string>
  onSet: (from: string, to: string | null) => void
  onClearAll: () => void
}) {
  if (props.candidates === null || props.candidates.length === 0) return null
  const candidates = props.candidates
  const allVars: Array<{ label: string; value: string | null }> = [
    { label: zhCN.variables.roles.outcome, value: props.draft.outcome_var },
    { label: zhCN.variables.roles.treatment, value: props.draft.treatment_var },
    ...props.draft.controls.map((v, idx) => ({ label: controlRoleLabel(idx + 1), value: v })),
  ]

  return (
    <div className="panel">
      <div className="panel-body">
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, alignItems: 'baseline' }}>
          <span className="section-label" style={{ margin: 0 }}>
            {zhCN.mapping.heading}
          </span>
          <button className="btn btn-secondary" type="button" onClick={props.onClearAll} disabled={props.locked}>
            {zhCN.mapping.clearAll}
          </button>
        </div>
        <div className="data-table-wrap" style={{ marginTop: 12, maxHeight: 280 }}>
          <table className="data-table">
            <thead>
              <tr>
                <th>{zhCN.mapping.headers.role}</th>
                <th>{zhCN.mapping.headers.original}</th>
                <th>{zhCN.mapping.headers.corrected}</th>
              </tr>
            </thead>
            <tbody>
              {allVars.map((v) => (
                <MappingRow
                  key={v.label}
                  label={v.label}
                  value={v.value}
                  candidates={candidates}
                  locked={props.locked}
                  corrected={v.value === null ? null : (props.variableCorrections[v.value] ?? null)}
                  onSet={props.onSet}
                />
              ))}
            </tbody>
          </table>
        </div>
        <div className="inline-hint" style={{ marginTop: 10 }}>
          {zhCN.mapping.hint}
        </div>
      </div>
    </div>
  )
}

function Stage1QuestionCard(props: {
  locked: boolean
  question: DraftStage1Question
  selected: string[]
  onSet: (next: string[]) => void
}) {
  const q = props.question
  const isMulti = q.question_type === 'multi_choice'
  return (
    <div className="panel inset-panel">
      <div className="panel-body">
        <div style={{ fontWeight: 600, marginBottom: 10 }}>{q.question_text}</div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
          {q.options.map((opt) => {
            const active = props.selected.includes(opt.option_id)
            return (
              <button
                key={opt.option_id}
                type="button"
                className={`btn btn-secondary${active ? ' btn-pill-active' : ''}`}
                disabled={props.locked}
                onClick={() => {
                  if (!isMulti) return props.onSet([opt.option_id])
                  const next = active ? props.selected.filter((x) => x !== opt.option_id) : [...props.selected, opt.option_id]
                  props.onSet(next)
                }}
              >
                {opt.label}
              </button>
            )
          })}
        </div>
      </div>
    </div>
  )
}

export function Stage1QuestionsPanel(props: {
  locked: boolean
  questions: DraftStage1Question[]
  answers: Record<string, string[]>
  onSetAnswer: (questionId: string, next: string[]) => void
}) {
  if (props.questions.length === 0) return null
  return (
    <div className="panel">
      <div className="panel-body">
        <span className="section-label" style={{ margin: 0 }}>
          {zhCN.stage1.heading}
        </span>
        <div style={{ display: 'grid', gap: 16, marginTop: 12 }}>
          {props.questions.map((q) => (
            <Stage1QuestionCard
              key={q.question_id}
              locked={props.locked}
              question={q}
              selected={props.answers[q.question_id] ?? []}
              onSet={(next) => props.onSetAnswer(q.question_id, next)}
            />
          ))}
        </div>
      </div>
    </div>
  )
}

function UnknownInput(props: { locked: boolean; unknown: DraftOpenUnknown; value: string; onChange: (v: string) => void }) {
  const u = props.unknown
  if (u.candidates !== undefined && u.candidates.length > 0) {
    return (
      <select value={props.value} disabled={props.locked} onChange={(e) => props.onChange(e.target.value)}>
        <option value="">{zhCN.common.selectPlaceholder}</option>
        {u.candidates.map((c) => (
          <option key={c} value={c}>
            {c}
          </option>
        ))}
      </select>
    )
  }
  return (
    <input
      type="text"
      value={props.value}
      className="mono"
      disabled={props.locked}
      placeholder={zhCN.unknowns.placeholderValue}
      onChange={(e) => props.onChange(e.target.value)}
    />
  )
}

function OpenUnknownCard(props: {
  locked: boolean
  unknown: DraftOpenUnknown
  value: string
  onChange: (v: string) => void
}) {
  const u = props.unknown
  const title =
    u.field === 'outcome_var'
      ? zhCN.variables.roles.outcome
      : u.field === 'treatment_var'
        ? zhCN.variables.roles.treatment
        : zhCN.unknowns.heading
  const description =
    u.field === 'outcome_var'
      ? '请选择因变量'
      : u.field === 'treatment_var'
        ? '请选择处理变量'
        : u.description
  return (
    <div className="panel inset-panel">
      <div className="panel-body">
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
          <div style={{ fontWeight: 600 }}>{title}</div>
          <div className="inline-hint">{isBlockingUnknown(u) ? zhCN.unknowns.blocking : zhCN.unknowns.nonBlocking}</div>
        </div>
        <div className="inline-hint" style={{ marginTop: 6 }}>
          {description}
        </div>
        <div style={{ marginTop: 10 }}>
          <UnknownInput locked={props.locked} unknown={u} value={props.value} onChange={props.onChange} />
        </div>
      </div>
    </div>
  )
}

export function OpenUnknownsPanel(props: {
  locked: boolean
  unknowns: DraftOpenUnknown[]
  values: Record<string, string>
  onChange: (field: string, value: string) => void
  patchSupported: boolean
  onPatch: () => void
  patchDisabledReason: string | null
}) {
  if (props.unknowns.length === 0) return null
  const hasBlocking = props.unknowns.some((u) => isBlockingUnknown(u))
  return (
    <div className="panel">
      <div className="panel-body">
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, alignItems: 'baseline' }}>
          <span className="section-label" style={{ margin: 0 }}>
            {zhCN.unknowns.heading}
          </span>
          {hasBlocking ? <span className="inline-hint">{zhCN.unknowns.hasBlockingHint}</span> : null}
        </div>
        <div style={{ display: 'grid', gap: 14, marginTop: 12 }}>
          {props.unknowns.map((u) => (
            <OpenUnknownCard
              key={u.field}
              locked={props.locked}
              unknown={u}
              value={props.values[u.field] ?? ''}
              onChange={(v) => props.onChange(u.field, v)}
            />
          ))}
        </div>
        {props.patchSupported ? (
          <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 14 }}>
            <button className="btn btn-secondary" type="button" onClick={props.onPatch} disabled={props.locked}>
              {zhCN.unknowns.applyAndRefresh}
            </button>
          </div>
        ) : (
          <div className="inline-hint" style={{ marginTop: 12 }}>
            {props.patchDisabledReason ?? zhCN.unknowns.patchUnsupported}
          </div>
        )}
      </div>
    </div>
  )
}

export function DowngradeModal(props: { open: boolean; onCancel: () => void; onConfirm: () => void }) {
  if (!props.open) return null
  return (
    <div className="modal-backdrop" role="dialog" aria-modal="true">
      <div className="modal">
        <div style={{ fontWeight: 700, marginBottom: 6 }}>{zhCN.downgrade.title}</div>
        <div className="inline-hint">{zhCN.downgrade.message}</div>
        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, marginTop: 16 }}>
          <button className="btn btn-secondary" type="button" onClick={props.onCancel}>
            {zhCN.actions.cancel}
          </button>
          <button className="btn btn-primary" type="button" onClick={props.onConfirm}>
            {zhCN.actions.continueConfirm}
          </button>
        </div>
      </div>
    </div>
  )
}
