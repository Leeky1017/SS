import type { AdminArtifactItem, AdminJobDetailResponse } from '../adminApiTypes'

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
              <div className="section-label">JOB</div>
              <div className="mono">
                {job.tenant_id} / {job.job_id}
              </div>
            </div>
            <div>
              <div className="section-label">STATUS</div>
              <div style={{ fontWeight: 600 }}>{job.status}</div>
            </div>
            <div style={{ display: 'flex', gap: 10, alignItems: 'end' }}>
              <button className="btn btn-secondary" type="button" onClick={props.onRetry} disabled={props.busy}>
                重试
              </button>
            </div>
          </div>
          <div style={{ marginTop: 10 }} className="inline-hint">
            created_at: <span className="mono">{job.created_at}</span>
          </div>
        </div>
      </div>

      <div className="panel">
        <div className="panel-body">
          <div className="section-label">REQUIREMENT</div>
          <div className="pre-wrap">{job.requirement ?? ''}</div>
        </div>
      </div>

      <div className="panel">
        <div className="panel-body">
          <div className="section-label">DRAFT</div>
          <div className="inline-hint" style={{ marginBottom: 8 }}>
            created_at: <span className="mono">{job.draft_created_at ?? ''}</span>
          </div>
          <div className="pre-wrap">{job.draft_text ?? ''}</div>
        </div>
      </div>

      <div className="panel">
        <div className="panel-body">
          <div className="section-label">RUNS</div>
          {job.runs.length === 0 ? (
            <div className="inline-hint">暂无 run 记录。</div>
          ) : (
            <div className="data-table-wrap">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>run_id</th>
                    <th>attempt</th>
                    <th>status</th>
                    <th>started_at</th>
                    <th>ended_at</th>
                    <th>artifacts_count</th>
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
          <div className="section-label">ARTIFACTS</div>
          {job.artifacts.length === 0 ? (
            <div className="inline-hint">暂无产物。</div>
          ) : (
            <div className="data-table-wrap" style={{ maxHeight: 340 }}>
              <table className="data-table">
                <thead>
                  <tr>
                    <th>kind</th>
                    <th>rel_path</th>
                    <th>created_at</th>
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

