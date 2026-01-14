import { useEffect, useState } from 'react'
import type { ApiError } from '../../../api/errors'
import { ErrorPanel } from '../../../components/ErrorPanel'
import type { AdminApiClient } from '../adminApi'
import type { AdminTokenItem } from '../adminApiTypes'

type AdminTokensPageProps = {
  api: AdminApiClient
  onAuthInvalid: () => void
}

export function AdminTokensPage(props: AdminTokensPageProps) {
  const [busy, setBusy] = useState<boolean>(false)
  const [error, setError] = useState<ApiError | null>(null)
  const [items, setItems] = useState<AdminTokenItem[]>([])

  const [createName, setCreateName] = useState<string>('personal')
  const [createdToken, setCreatedToken] = useState<string | null>(null)

  const refresh = async () => {
    if (busy) return
    setBusy(true)
    setError(null)
    const result = await props.api.listTokens()
    setBusy(false)

    if (!result.ok) {
      if (result.error.kind === 'unauthorized' || result.error.kind === 'forbidden') props.onAuthInvalid()
      setError(result.error)
      return
    }
    setItems(result.value.tokens)
  }

  useEffect(() => {
    void refresh()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const create = async () => {
    if (busy || createName.trim() === '') return
    setBusy(true)
    setError(null)
    setCreatedToken(null)
    const result = await props.api.createToken({ name: createName })
    setBusy(false)

    if (!result.ok) {
      if (result.error.kind === 'unauthorized' || result.error.kind === 'forbidden') props.onAuthInvalid()
      setError(result.error)
      return
    }
    setCreatedToken(result.value.token)
    await refresh()
  }

  const revoke = async (tokenId: string) => {
    if (busy) return
    setBusy(true)
    setError(null)
    const result = await props.api.revokeToken(tokenId)
    setBusy(false)

    if (!result.ok) {
      if (result.error.kind === 'unauthorized' || result.error.kind === 'forbidden') props.onAuthInvalid()
      setError(result.error)
      return
    }
    await refresh()
  }

  const del = async (tokenId: string) => {
    if (busy) return
    if (!window.confirm(`确认删除该凭证（编号：${tokenId}）？`)) return
    setBusy(true)
    setError(null)
    const result = await props.api.deleteToken(tokenId)
    setBusy(false)

    if (!result.ok) {
      if (result.error.kind === 'unauthorized' || result.error.kind === 'forbidden') props.onAuthInvalid()
      setError(result.error)
      return
    }
    await refresh()
  }

  return (
    <div className="view-fade">
      <h1>访问凭证管理</h1>
      <div className="lead">登录会创建会话凭证；也可创建长期凭证，并支持撤销/删除。</div>

      <ErrorPanel error={error} onRetry={() => void refresh()} />

      <div className="panel">
        <div className="panel-body">
          <div className="section-label">创建凭证</div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: 12, alignItems: 'end' }}>
            <div>
              <label className="section-label">名称</label>
              <input type="text" value={createName} onChange={(e) => setCreateName(e.target.value)} />
            </div>
            <button className="btn btn-primary" type="button" onClick={() => void create()} disabled={busy}>
              创建
            </button>
          </div>
          {createdToken === null ? null : (
            <div className="panel inset-panel" style={{ marginTop: 16 }}>
              <div className="panel-body">
                <div style={{ fontWeight: 600, marginBottom: 6 }}>新凭证（仅显示一次）</div>
                <div className="mono pre-wrap">{createdToken}</div>
              </div>
            </div>
          )}
        </div>
      </div>

      <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 12 }}>
        <button className="btn btn-secondary" type="button" onClick={() => void refresh()} disabled={busy}>
          {busy ? '刷新中…' : '刷新'}
        </button>
      </div>

      <div className="panel">
        <div className="panel-body">
          <div className="section-label">凭证列表</div>
          <div className="data-table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th>名称</th>
                  <th>编号</th>
                  <th>创建时间</th>
                  <th>最近使用</th>
                  <th>撤销时间</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {items.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="inline-hint">
                      暂无凭证
                    </td>
                  </tr>
                ) : (
                  items.map((t) => (
                    <tr key={t.token_id}>
                      <td>{t.name}</td>
                      <td className="mono">{t.token_id}</td>
                      <td className="mono">{t.created_at}</td>
                      <td className="mono">{t.last_used_at ?? ''}</td>
                      <td className="mono">{t.revoked_at ?? ''}</td>
                      <td>
                        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8 }}>
                          <button
                            className="btn btn-secondary"
                            type="button"
                            disabled={busy || t.revoked_at !== null}
                            onClick={() => void revoke(t.token_id)}
                          >
                            撤销
                          </button>
                          <button className="btn btn-secondary" type="button" disabled={busy} onClick={() => void del(t.token_id)}>
                            删除
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  )
}
