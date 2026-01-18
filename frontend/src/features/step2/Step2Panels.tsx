import type { InputsPreviewResponse } from '../../api/types'
import { Stepper } from '../../components/Stepper'

function clipCell(value: unknown): string {
  if (value === null || value === undefined) return '—'
  const asText = typeof value === 'string' ? value : String(value)
  return asText.length > 120 ? `${asText.slice(0, 120)}…` : asText
}

export function Step2Header() {
  return (
    <>
      <Stepper
        steps={[
          { label: '填写需求', state: 'done' },
          { label: '上传预览', state: 'active' },
          { label: '确认执行', state: 'upcoming' },
        ]}
      />
      <h1>上传数据并预览</h1>
      <p className="lead">支持 CSV/XLSX/DTA。可上传 1 个主文件 + 若干辅助文件；Excel 可选择工作表并刷新预览。</p>
    </>
  )
}

function PreviewTable(props: { preview: InputsPreviewResponse }) {
  const columns = props.preview.columns ?? []
  const sampleRows = props.preview.sample_rows ?? []
  const headers = columns.map((col) => col.name)
  return (
    <div className="data-table-wrap" style={{ marginTop: 12 }}>
      <table className="data-table">
        <thead>
          <tr>
            <th className="mono">#</th>
            {columns.map((col) => (
              <th key={col.name} className="mono">
                <div>{col.name}</div>
                <div className="inline-hint" style={{ marginTop: 4 }}>
                  {col.inferred_type}
                </div>
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {sampleRows.map((row, idx) => (
            <tr key={idx}>
              <td className="mono" style={{ color: 'var(--text-muted)' }}>
                {idx + 1}
              </td>
              {headers.map((name) => (
                <td key={name}>{clipCell(row[name])}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

function PreviewSkeleton() {
  return (
    <div className="panel">
      <div className="panel-body">
        <span className="section-label" style={{ margin: 0 }}>
          预览
        </span>
        <div style={{ display: 'grid', gap: 10, marginTop: 12 }}>
          <div className="skeleton" style={{ height: 12, width: '35%' }} />
          <div className="skeleton" style={{ height: 12, width: '55%' }} />
          <div className="skeleton" style={{ height: 220, borderRadius: 8 }} />
        </div>
      </div>
    </div>
  )
}

function PreviewPanelHeader(props: {
  preview: InputsPreviewResponse
  busy?: boolean
  rememberedSheet?: string | null
  onSelectSheet?: (sheetName: string) => void
}) {
  const sheetNames = props.preview.sheet_names ?? []
  const selectedSheet = props.preview.selected_sheet ?? null
  const headerRow = props.preview.header_row ?? null
  const columns = props.preview.columns ?? []
  const sampleRows = props.preview.sample_rows ?? []
  const totalCols = props.preview.column_count ?? columns.length
  const showingCols = columns.length
  const showingRows = sampleRows.length
  const rowCount = props.preview.row_count

  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, alignItems: 'baseline', flexWrap: 'wrap' }}>
      <span className="section-label" style={{ margin: 0 }}>
        预览
      </span>
      <div style={{ display: 'flex', gap: 12, alignItems: 'center', flexWrap: 'wrap', justifyContent: 'flex-end' }}>
        {props.onSelectSheet && sheetNames.length > 1 ? (
          <label className="inline-hint" style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
            工作表
            <select value={selectedSheet ?? ''} disabled={props.busy} onChange={(e) => props.onSelectSheet?.(e.target.value)}>
              {sheetNames.map((name) => (
                <option key={name} value={name}>
                  {name}
                </option>
              ))}
            </select>
          </label>
        ) : selectedSheet ? (
          <div className="inline-hint">工作表：{selectedSheet}</div>
        ) : null}
        {props.rememberedSheet ? <div className="inline-hint">已记住工作表：{props.rememberedSheet}</div> : null}
        <div className="inline-hint">行数：{rowCount ?? '未知'} · 列数：{totalCols} · 已显示：{showingRows}×{showingCols}</div>
        {headerRow === null ? null : <div className="inline-hint">首行为表头：{headerRow ? '是' : '否'}</div>}
      </div>
    </div>
  )
}

export function PreviewPanel(props: {
  preview: InputsPreviewResponse | null
  busy?: boolean
  rememberedSheet?: string | null
  onSelectSheet?: (sheetName: string) => void
}) {
  if (props.preview === null) return props.busy ? <PreviewSkeleton /> : null
  return (
    <div className="panel">
      <div className="panel-body">
        <PreviewPanelHeader preview={props.preview} busy={props.busy} rememberedSheet={props.rememberedSheet} onSelectSheet={props.onSelectSheet} />
        <PreviewTable preview={props.preview} />
      </div>
    </div>
  )
}
