# ISSUE-505
- Issue: #505 https://github.com/Leeky1017/SS/issues/505
- Branch: task/505-real-e2e-audit-gate
- PR: https://github.com/Leeky1017/SS/pull/506

## Goal
- 将 Windows 47.98 真实环境 E2E 升级为“审计级全覆盖”：plan/freeze + run + artifacts 证据断言 + 重启恢复验证；并作为 release gate 唯一门禁。

## Status
- CURRENT: PR merged (#506); follow-up cleanup tracked in #507.

## Next Actions
- [x] 修改 `scripts/ss_ssh_e2e/flow.py`（endpoint 覆盖 + 负例 + artifacts 强断言）
- [x] 修改 `scripts/ss_windows_release_gate.py`（restart recoverability + rollback 证据）
- [x] 跑 `ruff` / `pytest` + 47.98 实跑 gate 并记录证据路径
- [x] 创建 PR → auto-merge → 合并验证（PR #506 已合并）

## Decisions Made
- 2026-01-17: 以 `/plan/freeze` + `/plan` + `/run` 替换旧 `/confirm` 驱动链路（不保留可选开关），确保审计路径唯一且可追责。

## Errors Encountered
- 2026-01-17: 真实 LLM 可能已自动补全 open_unknowns，导致负例 missing_fields 仅包含 `stage1_questions.analysis_goal` → 放宽断言为至少包含该字段。
- 2026-01-17: restart 后 `/health/ready` 轮询遇到 `httpx.RemoteProtocolError` → 在 recoverability polling/HTTP 调用中捕获 `httpx.HTTPError` 并重试。

## Runs
### 2026-01-17 05:26 create issue
- Command:
  - `gh issue create -t "[OPS] Real E2E audit gate: full /v1 coverage + restart recoverability" -b "<acceptance>"`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/505`
- Evidence:
  - Issue: #505

### 2026-01-17 05:28 worktree setup
- Command:
  - `scripts/agent_worktree_setup.sh "505" "real-e2e-audit-gate"`
- Key output:
  - `Worktree created: .worktrees/issue-505-real-e2e-audit-gate`
  - `Branch: task/505-real-e2e-audit-gate`
- Evidence:
  - Local path: `.worktrees/issue-505-real-e2e-audit-gate`

### 2026-01-17 06:07 ruff
- Command:
  - `/home/leeky/work/SS/.venv/bin/ruff check .`
- Key output:
  - `All checks passed!`

### 2026-01-17 06:08 pytest
- Command:
  - `/home/leeky/work/SS/.venv/bin/pytest -q`
- Key output:
  - `432 passed, 7 skipped`

### 2026-01-17 06:15 gate run (failed; rollback ok)
- Command:
  - `/home/leeky/work/SS/.venv/bin/python scripts/ss_windows_release_gate.py --out-dir /tmp/ss_windows_release_gate/ISSUE-505-20260117T061513Z`
- Key output:
  - `deploy.ok=true e2e.ok=false rollback.ok=true`
- Evidence:
  - `/tmp/ss_windows_release_gate/ISSUE-505-20260117T061513Z/e2e/result.json`

### 2026-01-17 06:22 gate run (crash; fixed)
- Command:
  - `/home/leeky/work/SS/.venv/bin/python scripts/ss_windows_release_gate.py --out-dir /tmp/ss_windows_release_gate/ISSUE-505-20260117T062230Z`
- Key output:
  - `httpx.RemoteProtocolError (server disconnected without response)`
- Evidence:
  - `/tmp/ss_windows_release_gate/ISSUE-505-20260117T062230Z/e2e.stdout.txt`
  - `/tmp/ss_windows_release_gate/ISSUE-505-20260117T062230Z/restart.remote.txt`

### 2026-01-17 06:29 gate run (pass)
- Command:
  - `/home/leeky/work/SS/.venv/bin/python scripts/ss_windows_release_gate.py --out-dir /tmp/ss_windows_release_gate/ISSUE-505-20260117T062941Z`
- Key output:
  - `ok=true deploy.ok=true e2e.ok=true restart.ok=true recoverability.ok=true`
- Evidence:
  - `/tmp/ss_windows_release_gate/ISSUE-505-20260117T062941Z/result.json`
  - `/tmp/ss_windows_release_gate/ISSUE-505-20260117T062941Z/e2e/result.json`
  - `/tmp/ss_windows_release_gate/ISSUE-505-20260117T062941Z/e2e/artifacts/`
  - `/tmp/ss_windows_release_gate/ISSUE-505-20260117T062941Z/recoverability.plan.json`
