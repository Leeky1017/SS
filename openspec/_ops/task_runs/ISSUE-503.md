# ISSUE-503
- Issue: #503
- Branch: task/503-real-stata-e2e-gate
- PR: https://github.com/Leeky1017/SS/pull/504

## Goal
- Replace “post-deploy /health/ready only” with a real, black-box v1 E2E gate against the Windows runtime (real server + real worker + real Stata), verifying artifacts and collecting diagnosable evidence on failure.

## Status
- CURRENT: Repo-native remote E2E runner + Windows release gate implemented; validated locally (ruff/pytest) and on 47.98 via deploy+real E2E.

## Next Actions
- [x] Baseline-check remote runtime (ready + schtasks + queue depth) and record evidence.
- [x] Implement repo-native remote E2E runner (SSH tunnel + v1 flow + artifact verification + diagnostics).
- [x] Replace release/deploy gate to require real E2E (no dual-path), then deploy + validate on 47.98.
- [ ] Run `scripts/agent_pr_preflight.sh`, open PR (Closes #503), enable auto-merge.
- [ ] Verify PR is MERGED, then sync control plane + cleanup worktree.

## Decisions Made
- 2026-01-17: Use SSH port-forwarding to `127.0.0.1:8000` on the Windows host so E2E does not rely on public port exposure.
- 2026-01-17: Treat real E2E as the only post-switch gate (no health-only fallback), per “禁向后兼容”.

## Errors Encountered
- (none yet)

## Runs
### 2026-01-17 Setup: Issue + worktree
- Command:
  - `gh issue create -t "[E2E] Real Stata E2E Gate: replace post-deploy /health/ready" -b "..."`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "503" "real-stata-e2e-gate"`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/503`
  - `Worktree created: .worktrees/issue-503-real-stata-e2e-gate`
  - `Branch: task/503-real-stata-e2e-gate`
- Evidence:
  - (this file)

### 2026-01-17 Local: venv + lint + tests
- Command:
  - `python3 -m venv .venv && . .venv/bin/activate && pip install -e ".[dev]"`
  - `ruff check scripts/ss_ssh_e2e.py scripts/ss_ssh_e2e scripts/ss_windows_release_gate.py`
  - `pytest -q`
- Key output:
  - `All checks passed!`
  - `432 passed, 7 skipped`
- Evidence:
  - Local stdout (this run)

### 2026-01-17 Remote: deploy + real v1 E2E gate (47.98)
- Command:
  - `python3 scripts/ss_windows_release_gate.py --out-dir /tmp/ss_issue503_release_gate_run`
- Key output:
  - `deploy.ok=true`
  - `e2e.ok=true job_id=job_tc_4d5dad7453b16be0 status=succeeded`
  - `artifacts_downloaded: stata.do, stata.log, run.meta.json`
- Evidence:
  - `/tmp/ss_issue503_release_gate_run/result.json`
  - `/tmp/ss_issue503_release_gate_run/e2e/result.json`
  - `/tmp/ss_issue503_release_gate_run/e2e/diagnostics/schtasks_api.txt`
  - `/tmp/ss_issue503_release_gate_run/e2e/diagnostics/schtasks_worker.txt`
  - `/tmp/ss_issue503_release_gate_run/e2e/diagnostics/queue_depth.txt`
  - `/tmp/ss_issue503_release_gate_run/e2e/diagnostics/deploy_log_tail.txt`
