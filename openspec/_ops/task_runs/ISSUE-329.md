# ISSUE-329
- Issue: #329
- Branch: task/329-deploy-minio
- PR: (pending)

## Plan
- Add OpenSpec for Docker + MinIO (S3-compatible) uploads deployment.
- Add task cards for deploy assets + e2e self-check.
- Validate (openspec/ruff/pytest) and auto-merge PR.

## Runs
### 2026-01-10 issue + worktree
- Command: `gh issue create -t "[ROUND-01-OPS-A] DEPLOY-MINIO: Docker + MinIO as S3 upload backend" -b "<body>"`
- Key output: `https://github.com/Leeky1017/SS/issues/329`
- Evidence: `rulebook/tasks/issue-329-deploy-minio/`

### 2026-01-10 worktree setup
- Command: `scripts/agent_controlplane_sync.sh && scripts/agent_worktree_setup.sh "329" "deploy-minio"`
- Key output: `Worktree created: .worktrees/issue-329-deploy-minio`
- Evidence: `git branch --show-current`

### 2026-01-10 openspec validate
- Command: `openspec validate --specs --strict --no-interactive`
- Key output: `Totals: 28 passed, 0 failed (28 items)`
- Evidence: `openspec/specs/ss-deployment-docker-minio/spec.md`

### 2026-01-10 ruff
- Command: `python3 -m venv .venv && . .venv/bin/activate && pip install -e '.[dev]' && ruff check .`
- Key output: `All checks passed!`
- Evidence: `pyproject.toml`

### 2026-01-10 pytest
- Command: `. .venv/bin/activate && pytest -q`
- Key output: `176 passed, 5 skipped`
- Evidence: `tests/`
