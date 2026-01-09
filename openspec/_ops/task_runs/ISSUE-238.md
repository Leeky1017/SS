# ISSUE-238
- Issue: #238
- Branch: task/238-upload-c004-c006
- PR: <fill-after-created>

## Goal
- Implement UPLOAD-C004/C005/C006: upload-sessions issuance/refresh, finalize strong idempotency + manifest/fingerprint updates, and CI-stable anyio concurrency tests.

## Status
- CURRENT: Bootstrapped Issue/Rulebook task/worktree; implementing upload sessions API + finalize + tests.

## Next Actions
- [ ] Implement upload session issuance + refresh endpoints (direct + multipart).
- [ ] Implement finalize (strong idempotency; manifest + fingerprint; preview-compatible).
- [ ] Add anyio concurrency tests + stress/bench plan evidence.
- [ ] Run `ruff check .` + `pytest -q`, then preflight + PR + auto-merge.

## Decisions Made
- 2026-01-09: Use job-scoped file locks for upload-sessions state + finalize to ensure concurrency-safe idempotency with the file-based store.

## Errors Encountered
- 2026-01-09: Controlplane had untracked Rulebook artifacts → resolved via `git stash -u` before worktree setup.

## Runs
### 2026-01-09 Setup: gh auth + repo remotes
- Command:
  - `gh auth status`
  - `git remote -v`
- Key output:
  - `Logged in to github.com account Leeky1017`
  - `origin https://github.com/Leeky1017/SS.git (fetch/push)`

### 2026-01-09 Setup: create Issue #238
- Command:
  - `gh issue create -t "[ROUND-03-UPLOAD-A] UPLOAD-C004-C006: upload-sessions issuance/refresh + finalize idempotency + concurrency tests" -b "<body>"`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/238`

### 2026-01-09 Setup: Rulebook task
- Command:
  - `rulebook_task_create issue-238-upload-c004-c006`
  - `rulebook_task_validate issue-238-upload-c004-c006`
- Key output:
  - `valid: true`

### 2026-01-09 Setup: worktree
- Command:
  - `git stash push -u -m "wip: rulebook tasks issue-237/238"`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh 238 upload-c004-c006`
  - `git stash pop`
- Key output:
  - `Worktree created: .worktrees/issue-238-upload-c004-c006`
  - `Branch: task/238-upload-c004-c006`

### 2026-01-09 Setup: python env
- Command:
  - `python3 -m venv .venv`
  - `. .venv/bin/activate && pip install -e '.[dev]'`
- Key output:
  - `Successfully installed ... ruff ... pytest ...`

### 2026-01-09 Verify: ruff
- Command:
  - `. .venv/bin/activate && ruff check .`
- Key output:
  - `All checks passed!`

### 2026-01-09 Verify: pytest
- Command:
  - `. .venv/bin/activate && pytest -q`
- Key output:
  - `157 passed, 5 skipped`
- Evidence:
  - `tests/test_upload_sessions_api.py`
  - `tests/concurrent/test_upload_sessions_concurrency.py`
  - `rulebook/tasks/issue-238-upload-c004-c006/evidence/notes.md`
