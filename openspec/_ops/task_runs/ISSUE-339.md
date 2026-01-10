# ISSUE-339
- Issue: #339
- Branch: task/339-deploy-minio-r003
- PR: <fill-after-created>

## Plan
- Add repeatable Docker+MinIO uploads selfcheck (direct + multipart).
- Document multipart `ETag` capture + finalize payload.
- Record runnable evidence and outputs.

## Runs
### 2026-01-10 19:00 bootstrap
- Command: `gh issue create -t "[ROUND-01-OPS-A] DEPLOY-MINIO-R003: Docker+MinIO uploads E2E selfcheck" -b "<...>"`
- Key output: `https://github.com/Leeky1017/SS/issues/339`
- Evidence: `.worktrees/issue-339-deploy-minio-r003/openspec/specs/ss-deployment-docker-minio/task_cards/round-01-ops-a__DEPLOY-MINIO-R003.md`

### 2026-01-10 19:10 lint
- Command: `/home/leeky/work/SS/.venv/bin/ruff check .`
- Key output: `All checks passed!`
- Evidence: `.worktrees/issue-339-deploy-minio-r003`

### 2026-01-10 19:11 tests
- Command: `/home/leeky/work/SS/.venv/bin/pytest -q`
- Key output: `178 passed, 5 skipped in 9.53s`
- Evidence: `.worktrees/issue-339-deploy-minio-r003`

### 2026-01-10 19:14 uploads selfcheck (docker missing)
- Command: `cd openspec/specs/ss-deployment-docker-minio/assets && cp -f .env.example .env && bash uploads_e2e_selfcheck.sh`
- Key output: `ERROR: command failed: docker compose version (docker not available in this environment)`
- Evidence: `openspec/specs/ss-deployment-docker-minio/assets/uploads_e2e_selfcheck.sh`
