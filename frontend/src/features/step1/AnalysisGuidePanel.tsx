import { useMemo, useState } from 'react'
import {
  STEP1_METHOD_CATEGORIES,
  STEP1_METHOD_INDEX,
  STEP1_QUICK_FILLS,
  type Step1MethodCategory,
  type Step1MethodCategoryId,
  type Step1MethodId,
  getStep1Category,
  getStep1MethodTemplate,
} from './methodData'

type GuideState = { categoryId: Step1MethodCategoryId | null; methodId: Step1MethodId | null }

function CategoryCard(props: {
  active: boolean
  categoryId: Step1MethodCategoryId
  label: string
  description: string
  disabled: boolean
  onSelect: (categoryId: Step1MethodCategoryId) => void
}) {
  return (
    <button
      type="button"
      className={`panel inset-panel${props.active ? ' btn-pill-active' : ''}`}
      style={{ padding: 0, textAlign: 'left', width: '100%', cursor: props.disabled ? 'not-allowed' : 'pointer' }}
      disabled={props.disabled}
      onClick={() => props.onSelect(props.categoryId)}
    >
      <div className="panel-body">
        <div style={{ fontWeight: 650 }}>{props.label}</div>
        <div className="inline-hint" style={{ marginTop: 6 }}>
          {props.description}
        </div>
      </div>
    </button>
  )
}

function CategoryGrid(props: {
  busy: boolean
  activeCategoryId: Step1MethodCategoryId | null
  onSelectCategory: (categoryId: Step1MethodCategoryId) => void
}) {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))', gap: 12, marginTop: 12 }}>
      {STEP1_METHOD_CATEGORIES.map((c) => (
        <CategoryCard
          key={c.id}
          active={props.activeCategoryId === c.id}
          categoryId={c.id}
          label={c.label}
          description={c.description}
          disabled={props.busy}
          onSelect={props.onSelectCategory}
        />
      ))}
    </div>
  )
}

function MethodPills(props: {
  busy: boolean
  category: Step1MethodCategory
  activeMethodId: Step1MethodId | null
  onApplyMethod: (methodId: Step1MethodId) => void
}) {
  return (
    <div style={{ marginTop: 14 }}>
      <div className="inline-hint">子方法（{props.category.label}）</div>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginTop: 8 }}>
        {props.category.methods.map((m) => (
          <button
            key={m.id}
            className={`btn btn-secondary${props.activeMethodId === m.id ? ' btn-pill-active' : ''}`}
            type="button"
            disabled={props.busy}
            onClick={() => props.onApplyMethod(m.id)}
          >
            {m.label}
          </button>
        ))}
      </div>
    </div>
  )
}

function QuickFillRow(props: {
  busy: boolean
  activeMethodId: Step1MethodId | null
  onApplyMethod: (methodId: Step1MethodId) => void
}) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, alignItems: 'baseline', marginTop: 10 }}>
      <div className="inline-hint">快速填充</div>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', justifyContent: 'flex-end' }}>
        {STEP1_QUICK_FILLS.map((q) => (
          <button
            key={q.methodId}
            className={`btn btn-secondary${props.activeMethodId === q.methodId ? ' btn-pill-active' : ''}`}
            type="button"
            style={{ height: 28 }}
            disabled={props.busy}
            onClick={() => props.onApplyMethod(q.methodId)}
          >
            {q.label}
          </button>
        ))}
      </div>
    </div>
  )
}

export function AnalysisGuidePanel(props: { busy: boolean; onApplyTemplate: (template: string) => void }) {
  const [state, setState] = useState<GuideState>({ categoryId: null, methodId: null })

  const activeCategory = useMemo(
    () => (state.categoryId === null ? null : getStep1Category(state.categoryId)),
    [state.categoryId],
  )

  function selectCategory(categoryId: Step1MethodCategoryId): void {
    setState({ categoryId, methodId: null })
    if (categoryId === 'free_description') props.onApplyTemplate('')
  }

  function applyMethod(methodId: Step1MethodId): void {
    const categoryId = STEP1_METHOD_INDEX[methodId].categoryId
    setState({ categoryId, methodId })
    props.onApplyTemplate(getStep1MethodTemplate(methodId))
  }

  return (
    <div className="panel">
      <div className="panel-body">
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, alignItems: 'baseline' }}>
          <span className="section-label" style={{ margin: 0 }}>
            分析方法引导（可选）
          </span>
          <span className="inline-hint">选择后会自动生成可编辑模板</span>
        </div>

        <QuickFillRow busy={props.busy} activeMethodId={state.methodId} onApplyMethod={applyMethod} />
        <CategoryGrid busy={props.busy} activeCategoryId={state.categoryId} onSelectCategory={selectCategory} />
        {activeCategory !== null && activeCategory.methods.length > 0 ? (
          <MethodPills busy={props.busy} category={activeCategory} activeMethodId={state.methodId} onApplyMethod={applyMethod} />
        ) : null}
      </div>
    </div>
  )
}
