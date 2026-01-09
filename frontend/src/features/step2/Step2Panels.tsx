import { useMemo, useState } from 'react'
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
      <p className="lead">支持 CSV/XLSX/DTA。上传成功后可预览列名与样本行；若失败，错误态可重试且不丢失 job。</p>
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
            {headers.map((name) => (
              <th key={name} className="mono">
                {name}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {props.preview.sample_rows.map((row, idx) => (
            <tr key={idx}>
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

export function PreviewPanel(props: { preview: InputsPreviewResponse | null }) {
  if (props.preview === null) return null
  return (
    <div className="panel">
      <div className="panel-body">
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, alignItems: 'baseline' }}>
          <span className="section-label" style={{ margin: 0 }}>
            Preview
          </span>
          <div className="inline-hint">
            rows: {props.preview.row_count ?? 'n/a'} · columns: {props.preview.columns.length}
          </div>
        </div>
        <PreviewTable preview={props.preview} />
      </div>
    </div>
  )
}

export function DropZone(props: { busy: boolean; onPick: (files: File[]) => void }) {
  const [dragActive, setDragActive] = useState(false)
  const inputId = useMemo(() => `file_${Math.random().toString(16).slice(2)}`, [])

  return (
    <div
      className={`drop-zone${dragActive ? ' drop-zone-active' : ''}`}
      onDragOver={(e) => {
        e.preventDefault()
        setDragActive(true)
      }}
      onDragLeave={() => setDragActive(false)}
      onDrop={(e) => {
        e.preventDefault()
        setDragActive(false)
        const files = Array.from(e.dataTransfer.files)
        if (files.length > 0) props.onPick(files)
      }}
    >
      <div style={{ display: 'grid', gap: 10 }}>
        <div style={{ fontWeight: 600 }}>拖拽文件到此处上传</div>
        <div className="inline-hint">或点击选择文件（.csv / .xlsx / .dta）</div>
        <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
          <label className="btn btn-secondary" htmlFor={inputId} aria-disabled={props.busy}>
            选择文件
          </label>
        </div>
      </div>
      <input
        id={inputId}
        type="file"
        accept=".csv,.xlsx,.xls,.dta"
        style={{ display: 'none' }}
        disabled={props.busy}
        onChange={(e) => {
          const files = Array.from(e.target.files ?? [])
          if (files.length > 0) props.onPick(files)
          e.target.value = ''
        }}
      />
    </div>
  )
}

