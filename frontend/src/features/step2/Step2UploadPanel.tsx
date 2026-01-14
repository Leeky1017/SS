import { useMemo, useState } from 'react'

function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`
  const kb = bytes / 1024
  if (kb < 1024) return `${kb.toFixed(1)} KB`
  const mb = kb / 1024
  return `${mb.toFixed(1)} MB`
}

function FileRow(props: { file: File; onRemove: (() => void) | null }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, alignItems: 'center' }}>
      <div className="mono" style={{ color: 'var(--text-dim)', overflow: 'hidden', textOverflow: 'ellipsis' }}>
        {props.file.name}
      </div>
      <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
        <span className="mono" style={{ color: 'var(--text-muted)' }}>
          {formatBytes(props.file.size)}
        </span>
        {props.onRemove ? (
          <button className="btn btn-secondary" type="button" onClick={props.onRemove}>
            移除
          </button>
        ) : null}
      </div>
    </div>
  )
}

function FileDropArea(props: {
  busy: boolean
  title: string
  hint: string
  accept: string
  multiple: boolean
  onFiles: (files: File[]) => void
}) {
  const [dragActive, setDragActive] = useState(false)
  const inputId = useMemo(() => `file_${Math.random().toString(16).slice(2)}`, [])

  return (
    <div
      className={`drop-zone${dragActive ? ' drop-zone-active' : ''}`}
      style={{ marginBottom: 0 }}
      onDragOver={(e) => {
        e.preventDefault()
        setDragActive(true)
      }}
      onDragLeave={() => setDragActive(false)}
      onDrop={(e) => {
        e.preventDefault()
        setDragActive(false)
        const files = Array.from(e.dataTransfer.files)
        if (files.length > 0) props.onFiles(files)
      }}
    >
      <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, alignItems: 'baseline' }}>
        <div style={{ fontWeight: 600 }}>{props.title}</div>
        <label className="btn btn-secondary" htmlFor={inputId} aria-disabled={props.busy}>
          选择文件
        </label>
      </div>
      <div className="inline-hint" style={{ marginTop: 6 }}>
        {props.hint}
      </div>
      <input
        id={inputId}
        type="file"
        accept={props.accept}
        multiple={props.multiple}
        style={{ display: 'none' }}
        disabled={props.busy}
        onChange={(e) => {
          const files = Array.from(e.target.files ?? [])
          if (files.length > 0) props.onFiles(files)
          e.target.value = ''
        }}
      />
    </div>
  )
}

export function InputsUploadPanel(props: {
  busy: boolean
  primaryFile: File | null
  auxiliaryFiles: File[]
  onPickPrimary: (file: File) => void
  onClearPrimary: () => void
  onAddAuxiliary: (files: File[]) => void
  onRemoveAuxiliary: (index: number) => void
  onClearAuxiliary: () => void
  onUpload: () => void
}) {
  const accept = '.csv,.xlsx,.xls,.dta'
  const canUpload = props.primaryFile !== null && !props.busy

  return (
    <div className="panel">
      <div className="panel-body">
        <span className="section-label" style={{ margin: 0 }}>
          上传数据
        </span>
        <div className="inline-hint" style={{ marginTop: 8 }}>
          主文件将作为分析与变量识别的基础；辅助文件会一起保存，供后续按需使用。
        </div>

        <div style={{ display: 'grid', gap: 12, marginTop: 12 }}>
          <div style={{ display: 'grid', gap: 10 }}>
            <FileDropArea
              busy={props.busy}
              title="主文件（必选）"
              hint="拖拽或点击选择 1 个主数据文件（.csv / .xlsx / .dta）"
              accept={accept}
              multiple={false}
              onFiles={(files) => props.onPickPrimary(files[0])}
            />
            {props.primaryFile ? (
              <FileRow file={props.primaryFile} onRemove={props.busy ? null : props.onClearPrimary} />
            ) : (
              <div className="inline-hint">未选择主文件</div>
            )}
          </div>

          <div style={{ display: 'grid', gap: 10 }}>
            <FileDropArea
              busy={props.busy}
              title="辅助文件（可选，0~N）"
              hint="拖拽或点击选择多个辅助文件（如需合并的表、查找表等）"
              accept={accept}
              multiple={true}
              onFiles={(files) => props.onAddAuxiliary(files)}
            />
            {props.auxiliaryFiles.length > 0 ? (
              <div style={{ display: 'grid', gap: 8 }}>
                {props.auxiliaryFiles.map((file, index) => (
                  <FileRow
                    key={`${file.name}:${file.size}:${index}`}
                    file={file}
                    onRemove={props.busy ? null : () => props.onRemoveAuxiliary(index)}
                  />
                ))}
                {!props.busy ? (
                  <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
                    <button className="btn btn-secondary" type="button" onClick={props.onClearAuxiliary}>
                      清空辅助文件
                    </button>
                  </div>
                ) : null}
              </div>
            ) : (
              <div className="inline-hint">未选择辅助文件（可跳过）</div>
            )}
          </div>
        </div>

        <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 12 }}>
          <button className="btn btn-primary" type="button" disabled={!canUpload} onClick={props.onUpload}>
            上传并预览
          </button>
        </div>
      </div>
    </div>
  )
}
