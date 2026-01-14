import type { AdminArtifactItem, AdminJobDetailResponse } from '../adminApiTypes'
import { formatTaskReference } from '../../../utils/displayIds'

type AdminJobDetailPanelProps = {
  detail: AdminJobDetailResponse
  busy: boolean
  onRetry: () => void
  onDownloadArtifact: (artifact: AdminArtifactItem) => void
}

export function AdminJobDetailPanel(props: AdminJobDetailPanelProps) {
  const job = props.detail
  return (
    <>
      <div className="panel">
        <div className="panel-body">
          <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, flexWrap: 'wrap' }}>
            <div>
              <div className="section-label">任务</div>
              <div className="mono">
                {job.tenant_id} / {formatTaskReference(job.job_id)}
              </div>
            </div>
            <div>
              <div className="section-label">状态</div>
              <div style={{ fontWeight: 600 }}>{job.status}</div>
            </div>
            <div style={{ display: 'flex', gap: 10, alignItems: 'end' }}>
              <button className="btn btn-secondary" type="button" onClick={props.onRetry} disabled={props.busy}>
                重试
              </button>
            </div>
          </div>
          <div style={{ marginTop: 10 }} className="inline-hint">
            创建时间：<span className="mono">{job.created_at}</span>
          </div>
        </div>
      </div>

      <div className="panel">
        <div className="panel-body">
          <div className="section-label">需求描述</div>
          <div className="pre-wrap">{job.requirement ?? ''}</div>
        </div>
      </div>

      <div className="panel">
        <div className="panel-body">
          <div className="section-label">预览文本</div>
          <div className="inline-hint" style={{ marginBottom: 8 }}>
            创建时间：<span className="mono">{job.draft_created_at ?? ''}</span>
          </div>
          <div className="pre-wrap">{job.draft_text ?? ''}</div>
        </div>
      </div>

      <div className="panel">
        <div className="panel-body">
          <div className="section-label">执行记录</div>
          {job.runs.length === 0 ? (
            <div className="inline-hint">暂无执行记录。</div>
          ) : (
            <div className="data-table-wrap">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>执行编号</th>
                    <th>尝试次数</th>
                    <th>状态</th>
                    <th>开始时间</th>
                    <th>结束时间</th>
                    <th>文件数</th>
                  </tr>
                </thead>
                <tbody>
                  {job.runs.map((r) => (
                    <tr key={`${r.run_id}:${r.attempt}`}>
                      <td className="mono">{r.run_id}</td>
                      <td className="mono">{r.attempt}</td>
                      <td style={{ fontWeight: 600 }}>{r.status}</td>
                      <td className="mono">{r.started_at ?? ''}</td>
                      <td className="mono">{r.ended_at ?? ''}</td>
                      <td className="mono">{r.artifacts_count}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>

      <div className="panel">
        <div className="panel-body">
          <div className="section-label">文件列表</div>
          {job.artifacts.length === 0 ? (
            <div className="inline-hint">暂无文件。</div>
          ) : (
            <div className="data-table-wrap" style={{ maxHeight: 340 }}>
              <table className="data-table">
                <thead>
                  <tr>
                    <th>类型</th>
                    <th>路径</th>
                    <th>创建时间</th>
                    <th />
                  </tr>
                </thead>
                <tbody>
                  {job.artifacts.map((a) => (
                    <tr key={`${a.kind}:${a.rel_path}`}>
                      <td className="mono">{a.kind}</td>
                      <td className="mono">{a.rel_path}</td>
                      <td className="mono">{a.created_at ?? ''}</td>
                      <td>
                        <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
                          <button
                            className="btn btn-secondary"
                            type="button"
                            onClick={() => props.onDownloadArtifact(a)}
                            disabled={props.busy}
                          >
                            下载
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </>
  )
}
