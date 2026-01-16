# ISSUE-499
- Issue: #499
- Branch: task/499-p4-backend-quality
- PR: https://github.com/Leeky1017/SS/pull/500

## Plan
- 审计错误处理与日志一致性
- 落地修复并同步错误码清单
- 运行 ruff/mypy/pytest（含 e2e）

## Audit Findings
- `src/api/deps.py` 使用 `HTTPException(detail=...)`，导致错误响应为 `{"detail":...}`，不符合 `ss-api-surface` 的 `{"error_code","message"}` 契约
- FastAPI/Starlette 默认 `HTTPException`（如 404/405）与未捕获异常路径缺少统一结构化错误响应
- `ERROR_CODES.md` 缺失后端已使用的错误码：`JOB_LOCKED`
- API 缺少统一的结构化请求日志事件（含 `request_id`/path/route/status/duration）

## Fixes
- `src/api/deps.py`：将租户 header 校验错误改为抛出 `SSError`/`TenantIdUnsafeError`（统一结构化错误响应）
- `src/main.py`：新增 `SS_API_REQUEST` 请求日志（`request_id`/route/status/duration/client_ip），并补齐 `SS_API_ERROR_RESPONSE`/`SS_API_UNHANDLED_EXCEPTION` 日志
- `src/main.py`：新增 `StarletteHTTPException` 与通用 `Exception` handler，确保非 2xx 返回结构化错误；对 5xx 中疑似路径/堆栈信息的 message 做安全收敛
- `ERROR_CODES.md`：补齐 `JOB_LOCKED`、`SERVICE_INTERNAL_ERROR`、`API_NOT_FOUND`、`API_METHOD_NOT_ALLOWED`、`API_HTTP_ERROR`

## Runs
### 2026-01-16 13:54 setup
- Command: `gh issue view 499 --json url,title,state`
- Key output: `{"state":"OPEN","title":"[P4-BE] Backend: error handling & logging alignment","url":"https://github.com/Leeky1017/SS/issues/499"}`
- Evidence: `openspec/_ops/task_runs/ISSUE-499.md`

### 2026-01-16 19:35 validate: ruff
- Command: `.venv/bin/ruff check .`
- Key output: `All checks passed!`
- Evidence: `src/api/deps.py`, `src/main.py`

### 2026-01-16 19:35 validate: mypy
- Command: `.venv/bin/mypy`
- Key output: `Success: no issues found in 217 source files`
- Evidence: `src/`

### 2026-01-16 19:35 validate: pytest
- Command: `.venv/bin/pytest -q`
- Key output: `432 passed, 7 skipped`
- Evidence: `tests/`

### 2026-01-16 19:35 validate: e2e
- Command: `.venv/bin/pytest tests/e2e/ -q`
- Key output: `56 passed, 2 skipped`
- Evidence: `tests/e2e/`

### 2026-01-16 19:36 pr: preflight
- Command: `scripts/agent_pr_preflight.sh`
- Key output: `OK: no overlapping files with open PRs; OK: no hard dependencies found`
- Evidence: `scripts/agent_pr_preflight.sh`

### 2026-01-16 19:36 pr: create
- Command: `gh pr create ...`
- Key output: `https://github.com/Leeky1017/SS/pull/500`
- Evidence: `openspec/_ops/task_runs/ISSUE-499.md`

### 2026-01-16 19:37 pr: enable auto-merge
- Command: `gh pr merge --auto --squash 500`
- Key output: `auto-merge enabled`
- Evidence: `https://github.com/Leeky1017/SS/pull/500`

### 2026-01-16 19:38 pr: required checks
- Command: `gh pr checks --watch 500`
- Key output: `ci/pass; merge-serial/pass; openspec-log-guard/pass`
- Evidence: `https://github.com/Leeky1017/SS/pull/500/checks`

### 2026-01-16 19:39 pr: merged
- Command: `gh pr view 500 --json mergedAt,state,mergeStateStatus`
- Key output: `{\"state\":\"MERGED\",\"mergedAt\":\"2026-01-16T11:38:54Z\"}`
- Evidence: `https://github.com/Leeky1017/SS/pull/500`

### 2026-01-16 20:00 rulebook: archive
- Command: `rulebook_task_archive issue-499-p4-backend-quality`
- Key output: `archived to rulebook/tasks/archive/2026-01-16-issue-499-p4-backend-quality`
- Evidence: `https://github.com/Leeky1017/SS/pull/502`
