import type { InputsPreviewResponse, InputsUploadResponse } from '../../api/types'

function clipCell(value: unknown): string {
  if (value === null || value === undefined) return '—'
  const asText = typeof value === 'string' ? value : String(value)
  return asText.length > 120 ? `${asText.slice(0, 120)}…` : asText
}

export function Step2Header() {
  return (
    <>
      <div className="stepper">
        <div className="step-tick done" />
        <div className="step-tick active" />
        <div className="step-tick" />
      </div>
      <h1>上传数据并预览</h1>
      <p className="lead">支持 CSV/XLSX/DTA。可上传 1 个主文件 + 0~N 个辅助文件；Excel 支持 Sheet 选择并刷新预览。</p>
    </>
  )
}

export function JobPanel(props: { jobId: string; tokenPresent: boolean }) {
  return (
    <div className="panel">
      <div className="panel-body">
        <span className="section-label" style={{ margin: 0 }}>
          Current job
        </span>
        <div className="mono" style={{ marginTop: 8, color: 'var(--text-dim)' }}>
          job_id: {props.jobId}
        </div>
        <div className="mono" style={{ marginTop: 8, color: 'var(--text-muted)' }}>
          token: {props.tokenPresent ? 'present' : 'absent'}
        </div>
        {!props.tokenPresent ? (
          <div className="inline-hint" style={{ marginTop: 10 }}>
            当前 job 没有 token（可能来自 dev fallback create job）；鉴权启用后建议使用 redeem 获取 token。
          </div>
        ) : null}
      </div>
    </div>
  )
}

export function UploadResultPanel(props: { upload: InputsUploadResponse | null }) {
  if (props.upload === null) return null
  return (
    <div className="panel">
      <div className="panel-body">
        <span className="section-label" style={{ margin: 0 }}>
          Upload result
        </span>
        <div className="mono" style={{ marginTop: 8, color: 'var(--text-dim)' }}>
          manifest_rel_path: {props.upload.manifest_rel_path}
        </div>
        <div className="mono" style={{ marginTop: 8, color: 'var(--text-muted)' }}>
          fingerprint: {props.upload.fingerprint}
        </div>
      </div>
    </div>
  )
}

function PreviewTable(props: { preview: InputsPreviewResponse }) {
  const headers = props.preview.columns.map((col) => col.name)
  return (
    <div className="data-table-wrap" style={{ marginTop: 12 }}>
      <table className="data-table">
        <thead>
          <tr>
            <th className="mono">#</th>
            {props.preview.columns.map((col) => (
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
          {props.preview.sample_rows.map((row, idx) => (
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

export function PreviewPanel(props: {
  preview: InputsPreviewResponse | null
  busy?: boolean
  onSelectSheet?: (sheetName: string) => void
}) {
  if (props.preview === null) return null
  const sheetNames = props.preview.sheet_names ?? []
  const selectedSheet = props.preview.selected_sheet ?? null
  const headerRow = props.preview.header_row ?? null
  const totalCols = props.preview.column_count ?? props.preview.columns.length
  const showingCols = props.preview.columns.length
  const showingRows = props.preview.sample_rows.length
  return (
    <div className="panel">
      <div className="panel-body">
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, alignItems: 'baseline', flexWrap: 'wrap' }}>
          <span className="section-label" style={{ margin: 0 }}>
            Preview
          </span>
          <div style={{ display: 'flex', gap: 12, alignItems: 'center', flexWrap: 'wrap', justifyContent: 'flex-end' }}>
            {props.onSelectSheet && sheetNames.length > 1 ? (
              <label className="inline-hint" style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                Sheet
                <select
                  value={selectedSheet ?? ''}
                  disabled={props.busy}
                  onChange={(e) => props.onSelectSheet?.(e.target.value)}
                >
                  {sheetNames.map((name) => (
                    <option key={name} value={name}>
                      {name}
                    </option>
                  ))}
                </select>
              </label>
            ) : selectedSheet ? (
              <div className="inline-hint">sheet: {selectedSheet}</div>
            ) : null}
            <div className="inline-hint">
              rows: {props.preview.row_count ?? 'n/a'} · cols: {totalCols} · showing: {showingRows}×{showingCols}
              {headerRow === null ? '' : headerRow ? ' · header: yes' : ' · header: no'}
            </div>
          </div>
        </div>
        <PreviewTable preview={props.preview} />
      </div>
    </div>
  )
}
